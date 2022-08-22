import json, boto3, os, sys, uuid
from urllib.parse import unquote_plus

s3_client = boto3.client('s3')

def lambda_handler(event, context):
    text = event
    bucket_name = "example_test_bucket"                # Target S3 Bucket
    file_name = "test.txt"                         # Target file
    lambda_path = "/tmp/" + file_name              # Path of file being download
    s3_path = "output/" + file_name                # Path of file being uploaded
    
    file_object = open(lambda_path, 'a')           # Open downloaded file to append
    file_object.write("\n" + text)                 # Update downloaded file
    file_object.close()                            # Save and close edited file
    
    s3 = boto3.resource("s3")
    s3.meta.client.upload_file(lambda_path, bucket_name, file_name)
