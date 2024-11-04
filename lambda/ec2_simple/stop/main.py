import boto3
from datetime import datetime, timedelta

def is_day_before_patching(date_to_check=None):
    today = date_to_check or datetime.now().date()
    patching_months = [1, 4, 7, 10]  # January, April, July, October

    if today.month in patching_months:
        month_to_check = today
    else:
        month_to_check = (today.replace(day=1) + timedelta(days=31)).replace(day=1)
        if month_to_check.month not in patching_months:
            return False
    
    first_day_of_month = month_to_check.replace(day=1)
    days_to_add = (1 - first_day_of_month.weekday() + 7) % 7
    first_tuesday = first_day_of_month + timedelta(days=days_to_add)
    
    return today == first_tuesday - timedelta(days=1)
    
def lambda_handler(event, context):
    if is_day_before_patching():
        print("Today is the day before a patching day. Skipping instance shutdown.")
        return {
            "statusCode": 200,
            "body": "Skipped stopping instances as today is the day before patching.",
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
