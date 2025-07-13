import json
import boto3
import urllib3
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    """Update GuardDuty threat intelligence with latest malicious IPs"""
    
    s3_client = boto3.client('s3')
    
    # Sample threat IPs (in production, fetch from threat intelligence feeds)
    threat_ips = [
        "198.51.100.1",
        "203.0.113.1", 
        "192.0.2.1",
        "10.0.0.1",
        "172.16.0.1"
    ]
    
    # Create threat list content
    threat_content = "\n".join(threat_ips)
    
    try:
        # Upload updated threat list to S3
        bucket_name = "security-sim-demo-136228ae"
        key = "threat-list-updated.txt"
        
        s3_client.put_object(
            Bucket=bucket_name,
            Key=key,
            Body=threat_content,
            ContentType='text/plain'
        )
        
        logger.info(f"Updated threat intelligence list with {len(threat_ips)} IPs")
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': f'Successfully updated threat intelligence with {len(threat_ips)} IPs',
                'location': f's3://{bucket_name}/{key}'
            })
        }
        
    except Exception as e:
        logger.error(f"Error updating threat intelligence: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': str(e)
            })
        }
