import * as functions from 'firebase-functions';
import * as req from 'request';
import * as fs from 'fs';
import * as path from 'path';

let BEARER_TOKEN: string = "BEARER_TOKEN";

export const acquireCropBounds = functions.https.onRequest((request, response) => {
    let bearerToken: string = fs.readFileSync(path.join(__dirname, "../src/" + BEARER_TOKEN)).toString().trim();

    let visionRequest: string = JSON.stringify({
        "requests":[
            {
                "image":{
                    "source":{
                        "imageUri": "gs://instarip-1c336.appspot.com/6.png"
                    }
                },
                "features":[
                    {
                        "type":"DOCUMENT_TEXT_DETECTION"
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
    }, function(error, res, body) {
        if(error) {
            response.send(error);
        }
        else {
            response.send(cropBoundsFromVision(body.toString()));
        }
    });
});

function cropBoundsFromVision(body: string): string {
    return body;
} 