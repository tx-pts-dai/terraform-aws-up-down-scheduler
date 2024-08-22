import boto3

def lambda_handler(event, context):
    ec2 = boto3.client("ec2")
    instance_ids = event.get("instance_ids")
    try:
        response = ec2.start_instances(InstanceIds=instance_ids)
        print(response)
        return {
            "statusCode": 200,
            "body": f"Successfully started instances {instance_ids}",
            "response": response,
        }
    except Exception as e:
        print(f"Error starting instances {instance_ids}: {str(e)}")
        return {
            "statusCode": 500,
            "body": f"Error starting instances {instance_ids}: {str(e)}",
        }
