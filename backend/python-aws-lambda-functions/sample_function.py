import json
import os
import boto3
from datetime import datetime

def lambda_handler(event, context):
    """
    Sample Lambda function handler
    This is an example of how your Lambda functions should be structured
    """
    
    # Get environment variables
    environment = os.environ.get('ENVIRONMENT', 'unknown')
    project = os.environ.get('PROJECT', 'unknown')
    function_name = os.environ.get('FUNCTION', 'unknown')
    
    # Log the incoming event
    print(f"Function: {function_name}")
    print(f"Environment: {environment}")
    print(f"Project: {project}")
    print(f"Event: {json.dumps(event)}")
    
    try:
        # Your business logic here
        result = {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'message': 'Function executed successfully',
                'function': function_name,
                'environment': environment,
                'project': project,
                'timestamp': datetime.utcnow().isoformat(),
                'event_received': event
            })
        }
        
        return result
        
    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'error': 'Internal server error',
                'message': str(e),
                'function': function_name,
                'timestamp': datetime.utcnow().isoformat()
            })
        }
