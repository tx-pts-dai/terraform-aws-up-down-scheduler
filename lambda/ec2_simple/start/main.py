import boto3

def lambda_handler(event, context):
    ec2 = boto3.client("ec2")
    instance_id = event.get("instance_id")

    try:
        response = ec2.start_instances(InstanceIds=[instance_id])
        print(response)
        return {
            "statusCode": 200,
            "body": f"Successfully started instance {instance_id}",
            "response": response,
        }
    except Exception as e:
        print(f"Error starting instance {instance_id}: {str(e)}")
        return {
            "statusCode": 500,
            "body": f"Error starting instance {instance_id}: {str(e)}",
        }
