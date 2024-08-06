import boto3

def lambda_handler(event, context):
    desired_capacity = event["desired_capacity"]
    asg_name = event["asg_name"]
    ec2_client = boto3.client("ec2")
    try:
        response = ec2_client.update_auto_scaling_group(
            AutoScalingGroupName=asg_name, DesiredCapacity=desired_capacity
        )
        print(response)
        return {
            "statusCode": 200,
            "body": f"Successfully updated desired capacity to {desired_capacity}",
        }
    except Exception as e:
        print(f"Error updating capacity of autoscaling group {asg_name}: {str(e)}")
        return {"statusCode": 500, "body": f"Error updating desired capacity: {str(e)}"}
