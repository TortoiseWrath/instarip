let BEARER_TOKEN_LOCATION: string = "BEARER_TOKEN";

import * as functions from 'firebase-functions';
import * as req from 'request';
import * as fs from 'fs';
import * as path from 'path';
import * as admin from 'firebase-admin';
import * as os from 'os';

const { Storage } = require('@google-cloud/storage');
const gcs = new Storage('instarip-1c336');
const spawn = require('child-process-promise').spawn;

admin.initializeApp();
const db = admin.firestore();

function cropBoundsFromVision(body: any): string {

    const textAnnotations: Array<Object> = JSON.parse(body)["responses"][0]["textAnnotations"];
    console.log(textAnnotations);
    let bottomBoundary: number = 0;
    let topBoundary: number = 0;
    let username: string = "";
    textAnnotations.forEach((block, i) => {
        if ("description" in block) {
            if (!isNaN(block["description"])) {
                const nextBlock: Object = textAnnotations[i+1];
                if ("description" in nextBlock) {
                    if (nextBlock["description"] == "likes") {
                        //we're good fam
                        bottomBoundary = nextBlock["boundingPoly"]["vertices"][2]["y"];
                        const usernameBlock: Object = textAnnotations[i+2];
                        if ("description" in usernameBlock)
                            username = usernameBlock["description"];
                    }
                }
            }
        }
    });

    let alreadyFound: boolean = false;
    textAnnotations.forEach((block, i) => {
        if ("description" in block) {
            if (!alreadyFound && block["description"] == username) {
                topBoundary = block["boundingPoly"]["vertices"][0]["y"];
                alreadyFound = true;
            }
        }
    });

    return JSON.stringify({"bottomBoundary":bottomBoundary, "topBoundary": topBoundary});
}

export const acquireCropBounds = functions
    .https
    .onRequest((request, response) => {
    let bearerToken: string = fs.readFileSync(path.join(__dirname, "../src/" + BEARER_TOKEN_LOCATION)).toString().trim();

    let visionRequest: string = JSON.stringify({
        "requests": [
            {
                "image": {
                    "source": {
                        "imageUri": `gs://instarip-1c336.appspot.com/${request.body["imgName"]}`
                    }
                },
                "features": [
                    {
                        "type": "DOCUMENT_TEXT_DETECTION"
                    }
                ]
            }
        ]
    });

    req({
        method: 'POST',
        port: 443,
        auth: {
            'bearer': bearerToken
        },
        headers: {
            'Content-Type': 'application/json'
        },
        url: "https://vision.googleapis.com/v1/images:annotate",
        body: visionRequest
    }, function (error, res, body) {
        if (error) {
            response.send(error);
        }
        else {
            response.send(cropBoundsFromVision(body));
        }
    });
});

export const createUserRecord = functions.auth
    .user()
    .onCreate((user, context) => {
        const userRef = db.doc(`users/${user.uid}`);

        return userRef.set({
            email: user.email,
            createdAt: context.timestamp,
            uid: user.uid
        });
    });

export const fileAdded = functions.storage
    .bucket('instarip-1c336.appspot.com')
    .object()
    .onFinalize((object, context) => {
        if (object.name && object.name.startsWith('cropped_')) {
            return "all good";
        }
        if (context.auth) {
            const photosRef = db.doc(`users/${context.auth.uid}/folders/Uncategorized/photos`);
            photosRef.set({
                name: object.name,
                createdAt: context.timestamp
            }).catch();
        }
        else {
            if (object.name) {
                var objectPathArr = object.name.split("/");
                var objectName = objectPathArr[objectPathArr.length - 1];
                const photosRef = db.doc(`users/userOne/folders/Uncategorized/photos/${objectName}`);
                photosRef.set({
                    name: object.name,
                    createdAt: context.timestamp
                }).catch();
            }
        }

        const fileBucket = object.bucket;
        const filePath = object.name;
        const contentType = object.contentType;

        if (filePath) {
            console.log(filePath);
            let request: string = JSON.stringify({
                "imgName": filePath
            });
        
            req({
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                url: "https://us-central1-instarip-1c336.cloudfunctions.net/acquireCropBounds",
                body: request
            }, function (error, res, body) {
                if (error) {
                    return error;
                }
                else {
                    // Download file from bucket.
                    console.log(res.body);
                    var boundaries = JSON.parse(res.body);
                    console.log(boundaries);
                    const bucket = gcs.bucket(fileBucket);
                    const tempFilePath = path.join(os.tmpdir(), path.basename(filePath));
                    const metadata = {
                        contentType: contentType,
                    };
                    return bucket.file(filePath).download({
                        destination: tempFilePath,
                    }).then(() => {
                        console.log('Image downloaded locally to', tempFilePath);
                        // Generate a crop using ImageMagick.
                        
                        return spawn('convert', [tempFilePath, '-crop', '<200x200+0+0>', tempFilePath]);
                    }).then(() => {
                        console.log('Crop created at', tempFilePath);
                        // We add a 'cropped_' prefix to thumbnails file name. That's where we'll upload the crop.
                        const thumbFileName = `cropped_${path.basename(filePath)}`;
                        const thumbFilePath = path.join(path.dirname(filePath), thumbFileName);
                        // Uploading the cropped photo.
                        return bucket.upload(tempFilePath, {
                            destination: thumbFilePath,
                            metadata: metadata,
                        });
                        // Once the crop has been uploaded delete the local file to free up disk space.
                    }).then(() => fs.unlinkSync(tempFilePath));
                }
            });
            
        }
        return "it's chill";
    });
