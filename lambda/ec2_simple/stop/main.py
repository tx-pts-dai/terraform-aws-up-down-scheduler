import boto3

def lambda_handler(event, context):
    instance_ids = event["instance_ids"]
    try:
        ec2 = boto3.client('ec2')
        response = ec2.stop_instances(InstanceIds=instance_ids)
        print(response)
        return {
            "statusCode": 200,
            "body": f"Successfully stopped instance {instance_ids}",
            "response": response,
        }
    except Exception as e:
        print(f"Error stopping instance {instance_ids}: {str(e)}")
        return {
            "statusCode": 500,
            "body": f"Error stopping instance {instance_ids}: {str(e)}",
        }
