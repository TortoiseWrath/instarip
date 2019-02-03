const SERVICE_ACCOUNT_PATH: string = "service-account-credentials.json";
const PROJECT_NAME: string = "instarip-1c336";

import * as functions from 'firebase-functions';
import * as fs from 'fs';
import * as path from 'path';
import * as admin from 'firebase-admin';
import * as os from 'os';

const vision = require('@google-cloud/vision');
const { Storage } = require('@google-cloud/storage');
const gcs = new Storage(PROJECT_NAME);
const spawn = require('child-process-promise').spawn;

admin.initializeApp();
const db = admin.firestore();

async function getVision(imgName: string) {
    const client = new vision.ImageAnnotatorClient({
        projectId: PROJECT_NAME,
        keyFilename: SERVICE_ACCOUNT_PATH
    });

    const results = await client.documentTextDetection(
        `gs://${PROJECT_NAME}.appspot.com/${imgName}`
    );
    return results;
}

async function acquireCropBounds(imgName: string) {
    return cropBoundsFromVision(await getVision(imgName));
};

export const debug = functions.https.onRequest(async (request, response) => {
    const visionResult = await getVision(request.body["imgName"]);
    response.send(JSON.stringify({
        'vision': visionResult,
        'cropBounds': cropBoundsFromVision(visionResult)
    }));
});

function blockHeight(block: any): number {
    return block["boundingPoly"]["vertices"][2]["y"] - block["boundingPoly"]["vertices"][0]["y"];
}

function instagramCropBounds(textAnnotations: Array<any>): string {
    let likesBlockIndex: number = 0;
    let username: string = "";

    // Look for an Instagram post likes row
    for(let i: number = 1; i < textAnnotations.length; i++) { // linter gets mad if I do let i in textAnnotations
        if(
            (
                /^(like|view)s?$/.test(textAnnotations[i]["description"]) 
                && /^[0-9,]+$/.test(textAnnotations[i - 1]["description"])
            )
            || (
                textAnnotations[i]["description"] === "Liked"
                && i !== textAnnotations.length - 1 
                && textAnnotations[i + 1]["description"] === "by"
            )
         ) {
            console.log("yeet");
            likesBlockIndex = i;
            // Advance to description
            while(++i < textAnnotations.length && textAnnotations[i]["boundingPoly"]["vertices"][0]["y"] < textAnnotations[i - 1]["boundingPoly"]["vertices"][2]["y"]);
            username = textAnnotations[i]["description"];
            break;
        }
    }

    // Return crop bounds for instagram post
    if(likesBlockIndex) {
        const em: number = blockHeight(textAnnotations[likesBlockIndex]); // 1 em ~= height of likes block
        let bottomCrop: number = textAnnotations[likesBlockIndex]["boundingPoly"]["vertices"][0]["y"] - 3 * em; // 3 em above likes block
        let topCrop: number = 0;
        for(let i: number = likesBlockIndex; i > 0; i--) { // go back to top block
            if(textAnnotations[i]["description"] === username // find username
                || (textAnnotations[i]["description"] === "Instagram" && blockHeight(textAnnotations[i]) > 1.1 * em)) { // or Instagram logo
                topCrop = textAnnotations[i]["boundingPoly"]["vertices"][2]["y"] + 1.05 * em; // 1.05 em below bottom
                break;
            }
        }
        return JSON.stringify({ "bottomBoundary": Math.round(bottomCrop), "topBoundary": Math.round(topCrop) });
    }

    return "god damn it all";
}

function twitterCropBounds(textAnnotations: Array<any>): string {
    const atSignIndex: number = scanTweet(textAnnotations, 1);
    if(!atSignIndex) return "fuck you twitter"; // no match

    let topBound: number = 0;
    let bottomBound: number = 0;
    let replied: boolean = false;
    
    // Look for replied line
    let i: number = atSignIndex;
    // Go back to start of line
    while(--i && textAnnotations[i]["boundingPoly"]["vertices"][2]["y"] > textAnnotations[i + 1]["boundingPoly"]["vertices"][0]["y"]);
    if(textAnnotations[i]["description"] === "replied") {
        replied = true;
        topBound = textAnnotations[i]["boundingPoly"]["vertices"][0]["y"];
        i++;
    }
    else {
        topBound = textAnnotations[++i]["boundingPoly"]["vertices"][0]["y"];
    }
    // Go to end of line
    while(++i < textAnnotations.length && textAnnotations[i]["boundingPoly"]["vertices"][0]["y"] < textAnnotations[i - 1]["boundingPoly"]["vertices"][2]["y"]);

    // Advance 1 or 2 tweets
    for(let j: number = 0; j < (replied ? 3 : 2); j++) {
        i = scanTweet(textAnnotations, i);
    }

    const em: number = blockHeight(textAnnotations[i]);

    // Go to start of line
    while(--i && textAnnotations[i]["boundingPoly"]["vertices"][2]["y"] > textAnnotations[i + 1]["boundingPoly"]["vertices"][0]["y"]);

    // Look for replied/retweeted line on subsequent tweet
    if(/^re/.test(textAnnotations[--i]["description"])) {
        // Go back to start of line
        while(--i && textAnnotations[i]["boundingPoly"]["vertices"][2]["y"] > textAnnotations[i + 1]["boundingPoly"]["vertices"][0]["y"]);
    }

    bottomBound = textAnnotations[i]["boundingPoly"]["vertices"][0]["y"] - em;

    return JSON.stringify({ "bottomBoundary": Math.round(bottomBound), "topBoundary": Math.round(topBound) });
}

function cropBoundsFromVision(body: any): string {
    const textAnnotations: Array<any> = body[0]["textAnnotations"];

    const instaBounds: string = instagramCropBounds(textAnnotations);
    if(instaBounds !== "god damn it all") return instaBounds;

    const twitterBounds: string = twitterCropBounds(textAnnotations);
    if(twitterBounds !== "fuck you twitter") return twitterBounds;

    return("we love you amber");
}

function scanTweet(textAnnotations: Array<any>, start: number): number {
    // Look for tweeter line
    for(let i: number = start; i < textAnnotations.length; i++) { // linter gets mad if I do let i in textAnnotations
        if(textAnnotations[i]["description"] === "@") {
            const potentialAtSignIndex: number = i;
            // Go to end of line
            while(++i < textAnnotations.length && textAnnotations[i]["boundingPoly"]["vertices"][0]["y"] < textAnnotations[i - 1]["boundingPoly"]["vertices"][2]["y"]);
            const lastElementOfTimestamp: RegExp = /^([0-9]{1,3}[smdh]?|[A-Za-z]{3})$/;
            if(!lastElementOfTimestamp.test(textAnnotations[--i]["description"])) {
                i--; // advance back up to 2 spaces to find last element of timestamp
            }
            if(lastElementOfTimestamp.test(textAnnotations[i]["description"])) {
                if(/^[0-9]{2}$/.test(textAnnotations[i]["description"])) { // 19 Jan 18
                    if(/^[A-Za-z]{3}$/.test(textAnnotations[--i]["description"])) {
                        if(/^[0-9]{1,2}$/.test(textAnnotations[--i]["description"])) {
                            // we got a tweet bois
                            return potentialAtSignIndex;
                        }
                    }
                }
                else if(/^[A-Za-z]{3}$/.test(textAnnotations[i]["description"])) { // 19 Jan
                    if(/^[0-9]{1,2}$/.test(textAnnotations[--i]["description"])) {
                        // oh look a tweet
                        return potentialAtSignIndex;
                    }
                }
                else { // 29s
                    // holy shit a tweet what now
                    return potentialAtSignIndex;
                }
                continue; // not a tweet
            }
        }
    }
    return 0; // no tweet
}

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
    .bucket(`${PROJECT_NAME}.appspot.com`)
    .object()
    .onFinalize(async (object, context) => {
        if (object.name && path.basename(object.name).startsWith('cropped_')) {
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
                const objectPathArr: string[] = object.name.split("/");
                const objectName: string = objectPathArr[objectPathArr.length - 1];
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
            //use filePath

            //call acquireCropBounds
            const result: string = await acquireCropBounds(filePath);
            // Download file from bucket.
            console.log(result);
            const boundaries = JSON.parse(result);
            const height: number = boundaries["bottomBoundary"] - boundaries["topBoundary"];
            const photoNameData: string[] = filePath.split("-");
            const width: number = parseInt(photoNameData[photoNameData.length - 1].split("x")[0]);
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

                return spawn('convert', [tempFilePath, '-crop', `<${width}x${height}+0+${boundaries["topBoundary"]}>`, tempFilePath]);
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
        return "it's chill";
    });
