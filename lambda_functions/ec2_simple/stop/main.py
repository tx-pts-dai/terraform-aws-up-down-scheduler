import boto3
from datetime import datetime, timedelta

def lambda_handler(event, context):
    tomorrow = datetime.now().date() + timedelta(days=1)
    patching_dates = event["patching_dates"]
    if tomorrow in patching_dates:
        print(f"Tomorrow is a patching day. Skipping instance shutdown.")
        return {
            "statusCode": 200,
            "body": "Skipped stopping instances as tomorrow is a patching day.",
        }

    instance_ids = event["instance_ids"]
    try:
        ec2 = boto3.client('ec2')
        response = ec2.stop_instances(InstanceIds=instance_ids)
        print(response)
        return {
            "statusCode": 200,
            "body": f"Successfully stopped instances {instance_ids}",
            "response": response,
        }
    except Exception as e:
        print(f"Error stopping instances {instance_ids}: {str(e)}")
        return {
            "statusCode": 500,
            "body": f"Error stopping instances {instance_ids}: {str(e)}",
        }
