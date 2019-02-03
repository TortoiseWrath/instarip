const SERVICE_ACCOUNT_PATH: string = "service-account-credentials.json";
const PROJECT_NAME: string = "instarip-1c336.appspot.com";

import * as functions from 'firebase-functions';
import * as fs from 'fs';
import * as path from 'path';
import * as admin from 'firebase-admin';
import * as os from 'os';

const vision = require('@google-cloud/vision');
const {Storage} = require('@google-cloud/storage');
const gcs = new Storage(PROJECT_NAME);
const spawn = require('child-process-promise').spawn;

admin.initializeApp();
const db = admin.firestore();

export const acquireCropBounds = functions.https.onRequest((request, response) => {
    const client = new vision.ImageAnnotatorClient({
        projectId: 'instarip-lc336',
        keyFilename: SERVICE_ACCOUNT_PATH
    });

    client.documentTextDetection(
        `gs://${PROJECT_NAME}/6.png` 
    ).then((results: any) => {
        response.send(cropBoundsFromVision(results));
    });
});

function cropBoundsFromVision(body: any): string {
    return body;
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
    .bucket(PROJECT_NAME + '.appspot.com')
    .object()
    .onFinalize((object, context) => {
        if (object.name && object.name.startsWith('cropped_')){
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
            const photosRef = db.doc(`users/userOne/folders/Uncategorized/photos/${object.name}`);
            photosRef.set({
                name: object.name,
                createdAt: context.timestamp
            }).catch();
        }
        
        const fileBucket = object.bucket; 
        const filePath = object.name; 
        const contentType = object.contentType;

        var fileName = '';
        if (filePath)
            fileName = path.basename(filePath);
        if (filePath && fileName != '') {
            // Download file from bucket.
            const bucket = gcs.bucket(fileBucket);
            const tempFilePath = path.join(os.tmpdir(), fileName);
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
            const thumbFileName = `cropped_${fileName}`;
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
