# AWS Terrfaform modules
This is a list of terraform modules which allow quickly deploying common patterns on AWS. 
Those try to stick to the best deployment recommendations such as: least privilege, encryption at rest/in transit, resiliency, etc.
They typically help to iterate fast, when deploying new functionalitites. And make reusability of best practices a no brainer.

Here are the most useful ones:

## Cdn
This deploys a cloudfront distribution and an S3 bucket. 
* It deploys using https only. 
* Files on S3 are encrypted 
* Files on S3 can only be accessed throught cloudfront. 
* It optionally supports custom domain name.
* It can be linked to a local folder and will automatically invalidate the cloudfront distribution when files change.

## Cors
Allows quickly adding CORS support to an api gateway resources

## *_lambda
Hook events from different sources to lambda function. This includes the proper policy and pemission setup.
This supports:
* dynamodb
* api gateway
* event bridge
* sqs
* s3

## lambda
Quickly deploy a lambda function, including the role. It can be deployed within a VPC and it automatically syncs with a local folder containing the app to be deployed.

## lambda_api
Make a lambda function available behind an api gateway based endpoint. The following are optional:
* api key
* CORS
* Cognito
* VPC

## lambda_cron
Invoke a lambda on a cron expression basis. Behind the scene it takes care of permissions and it uses event bridge.

## quotas
Can be added to any account. It creates cloud watch alarm for monitoring all account quotas.

## s3
Deploys a secured s3 bucket following recommended best practices.
