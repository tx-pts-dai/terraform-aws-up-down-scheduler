import boto3

def lambda_handler(event, context):
    instance_id = event['instance_id']
    try:
        ec2 = boto3.client('ec2')
        response = ec2.stop_instances(InstanceIds=[instance_id])
        print(response)
        return {
            "statusCode": 200,
            "body": f"Successfully stopped instance {instance_id}",
            "response": response,
        }
    except Exception as e:
        print(f"Error stopping instance {instance_id}: {str(e)}")
        return {
            "statusCode": 500,
            "body": f"Error stopping instance {instance_id}: {str(e)}",
        }
