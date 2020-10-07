/**
 * Splunk logging for AWS Lambda
 *
 * This function logs to a Splunk host using Splunk's HTTP event collector API.
 *
 * Define the following Environment Variables in the console below to configure
 * this function to log to your Splunk host:
 *
 * 1. SPLUNK_HEC_URL: URL address for your Splunk HTTP event collector endpoint.
 * Default port for event collector is 8088. Example: https://host.com:8088/services/collector
 *
 * 2. SPLUNK_HEC_TOKEN: Token for your Splunk HTTP event collector.
 * To create a new token for this Lambda function, refer to Splunk Docs:
 * http://docs.splunk.com/Documentation/Splunk/latest/Data/UsetheHTTPEventCollector#Create_an_Event_Col...
 */

'use strict';

const loggerConfig = {
    url: process.env.SPLUNK_HEC_URL,                                   //Provide the Splunk HEC url
    token: process.env.SPLUNK_HEC_TOKEN                         //Provide the Splunk HEC Token
};
var region='us-east-1'                                               //Change the region accordingly 
const SplunkLogger = require('./lib/mysplunklogger');
const aws = require('aws-sdk');
const logger = new SplunkLogger(loggerConfig);
const s3 = new aws.S3({
            apiVersion: '2006-03-01',
            region: region

 });

exports.handler = (event, context, callback) => {
    var objData = {};
    let functionname = JSON.stringify(context.functionName)
    var objectData
    var obj1 ;
    console.log('Received event:', JSON.stringify(event, null, 2));
    // Log JSON objects to Splunk
    var srcBucket = event.Records[0].s3.bucket.name;                 //Read the name of S3 bucket from the event object
    var srcKey    = event['Records'][0]['s3']['object']['key'];     //Read the name of S3 object from the event object
    var params = {
    Bucket: srcBucket, 
    Key: srcKey
    };
    s3.getObject(params, function(err, data)                        //Get object API call to S3 bucket to fetch the object
    {
    if (err) console.log(err, err.stack); // an error occurred
      else {
        objectData = data.Body.toString('utf-8');                  //convert the object to string
        console.log(objectData);
        //obj1=objectData;
        objData = objectData; //JSON.parse(objectData);
        console.log(objData);
        let account_id = JSON.stringify(context.invokedFunctionArn).split(':')[4];
        console.log(`AWS Account ID:  ${account_id} and Account Name : ${process.env.aws_account_name} S3 Bucket name:  ${srcBucket} Functiion Name : ${functionname} Decoded Payload : ${objData} `);
        logger.log(`AWS Account ID:  ${account_id} and Account Name : ${process.env.aws_account_name} S3 Bucket name:  ${srcBucket} Function Name : ${functionname} Decoded Payload : ${objData}`);
        //console.log(context);
        logger.log(objData);    
        
        }           // successful response
    });

    // Log JSON objects with optional 'context' argument (recommended)
    // This adds valuable Lambda metadata including functionName as source, awsRequestId as field
    //logger.log(event, context);

    // Log strings
   // logger.log(`value1 = ${event.key1}`, context);

    // Log with user-specified timestamp - useful for forwarding events with embedded
    // timestamps, such as from AWS IoT, AWS Kinesis, AWS CloudWatch Logs
    // Change "Date.now()" below to event timestamp if specified in event payload
    //logger.logWithTime(Date.now(), event, context);

    // Advanced:
    // Log event with user-specified request parameters - useful to set input settings per event vs token-level
    // Full list of request parameters available here:
    // http://docs.splunk.com/Documentation/Splunk/latest/RESTREF/RESTinput#services.2Fcollector
    
    logger.logEvent({
        time: Date.now(),
        host: 'serverless',
        source: `lambda:${functionname}:bk-lAMBDA-S3-SPLUNK`,
        sourcetype: 'httpevent',
        event:  objData
        
    });

    // Send all the events in a single batch to Splunk
    logger.flushAsync((error, response, body) => {
        if (error) {
            callback(error);
            console.log("Failed");
        } else {
            let account_id = JSON.stringify(context.invokedFunctionArn).split(':')[4];
            console.log(`AWS Account ID: ${account_id} and Account Name: ${process.env.aws_account_name}`);
            //console.log(context);
            console.log(`Response from Splunk:\n${response}`);
            //console.log(`Response from Splunk: ${body}`);
            callback(null, event.key1); // Echo back the first key value
        }
    });
};
