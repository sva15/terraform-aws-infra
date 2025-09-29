import json
import boto3
import psycopg2
import os
import logging
from botocore.exceptions import ClientError

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def get_secret(secret_name, region_name):
    """
    Retrieve secret from AWS Secrets Manager
    """
    session = boto3.session.Session()
    client = session.client(
        service_name='secretsmanager',
        region_name=region_name
    )
    
    try:
        get_secret_value_response = client.get_secret_value(SecretId=secret_name)
        secret = json.loads(get_secret_value_response['SecretString'])
        return secret
    except ClientError as e:
        logger.error(f"Error retrieving secret {secret_name}: {str(e)}")
        raise e

def get_database_credentials():
    """
    Get database credentials from environment variables or Secrets Manager
    """
    use_secrets_manager = os.environ.get('USE_SECRETS_MANAGER', 'true').lower() == 'true'
    
    if use_secrets_manager:
        # Get credentials from Secrets Manager
        secret_name = os.environ.get('DB_SECRET_NAME')
        region = os.environ.get('AWS_REGION', 'us-east-1')
        
        if not secret_name:
            raise ValueError("DB_SECRET_NAME environment variable is required when using Secrets Manager")
        
        logger.info(f"Retrieving database credentials from Secrets Manager: {secret_name}")
        secret = get_secret(secret_name, region)
        
        return {
            'host': secret.get('host', os.environ.get('RDS_HOST')),
            'port': secret.get('port', os.environ.get('RDS_PORT', '5432')),
            'database': secret.get('dbname', os.environ.get('RDS_DB_NAME')),
            'username': secret.get('username', os.environ.get('RDS_USERNAME')),
            'password': secret['password']
        }
    else:
        # Use environment variables (legacy method)
        logger.info("Using database credentials from environment variables")
        return {
            'host': os.environ.get('RDS_HOST'),
            'port': os.environ.get('RDS_PORT', '5432'),
            'database': os.environ.get('RDS_DB_NAME'),
            'username': os.environ.get('RDS_USERNAME'),
            'password': os.environ.get('RDS_PASSWORD')
        }

def handler(event, context):
    """
    Lambda function to restore PostgreSQL database from S3 backup
    """
    try:
        # Get database credentials
        db_credentials = get_database_credentials()
        
        rds_endpoint = db_credentials['host']
        rds_port = int(db_credentials['port'])
        db_name = db_credentials['database']
        db_username = db_credentials['username']
        db_password = db_credentials['password']
        s3_bucket = os.environ.get('S3_BUCKET', '')
        s3_key = os.environ.get('S3_KEY', '')
        
        logger.info(f"Starting database restoration for {db_name} on {rds_endpoint}")
        
        # Check if S3 backup is configured
        if not s3_bucket or not s3_key:
            logger.warning("No S3 backup configuration found, skipping restoration")
            return {
                'statusCode': 200,
                'body': json.dumps({
                    'message': 'No backup file configured, skipping restoration',
                    'status': 'skipped'
                })
            }
        
        # Download SQL file from S3
        s3_client = boto3.client('s3')
        local_sql_file = '/tmp/backup.sql'
        
        logger.info(f"Downloading backup from s3://{s3_bucket}/{s3_key}")
        s3_client.download_file(s3_bucket, s3_key, local_sql_file)
        
        # Wait for RDS to be available
        logger.info("Waiting for RDS instance to be available...")
        rds_client = boto3.client('rds')
        
        # Get RDS instance identifier from endpoint
        db_identifier = rds_endpoint.split('.')[0]
        
        waiter = rds_client.get_waiter('db_instance_available')
        waiter.wait(
            DBInstanceIdentifier=db_identifier,
            WaiterConfig={
                'Delay': 30,
                'MaxAttempts': 20
            }
        )
        
        # Connect to PostgreSQL
        logger.info("Connecting to PostgreSQL database...")
        connection = psycopg2.connect(
            host=rds_endpoint,
            port=rds_port,
            database=db_name,
            user=db_username,
            password=db_password,
            connect_timeout=30
        )
        
        connection.autocommit = True
        cursor = connection.cursor()
        
        # Read and execute SQL file
        logger.info("Reading SQL backup file...")
        with open(local_sql_file, 'r', encoding='utf-8') as sql_file:
            sql_content = sql_file.read()
        
        # Split SQL content into individual statements
        sql_statements = [stmt.strip() for stmt in sql_content.split(';') if stmt.strip()]
        
        logger.info(f"Executing {len(sql_statements)} SQL statements...")
        
        executed_statements = 0
        for i, statement in enumerate(sql_statements):
            try:
                if statement.strip():
                    cursor.execute(statement)
                    executed_statements += 1
                    
                    # Log progress every 100 statements
                    if (i + 1) % 100 == 0:
                        logger.info(f"Executed {i + 1}/{len(sql_statements)} statements")
                        
            except psycopg2.Error as e:
                logger.warning(f"Error executing statement {i + 1}: {str(e)}")
                # Continue with next statement for non-critical errors
                continue
        
        # Verify restoration
        cursor.execute("SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';")
        table_count = cursor.fetchone()[0]
        
        cursor.execute("SELECT current_database(), current_user;")
        db_info = cursor.fetchone()
        
        # Close connections
        cursor.close()
        connection.close()
        
        # Clean up temporary file
        os.remove(local_sql_file)
        
        logger.info(f"Database restoration completed successfully!")
        logger.info(f"Database: {db_info[0]}, User: {db_info[1]}, Tables: {table_count}")
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Database restoration completed successfully',
                'status': 'success',
                'database': db_info[0],
                'user': db_info[1],
                'tables_count': table_count,
                'statements_executed': executed_statements
            })
        }
        
    except ClientError as e:
        error_msg = f"AWS error during restoration: {str(e)}"
        logger.error(error_msg)
        return {
            'statusCode': 500,
            'body': json.dumps({
                'message': error_msg,
                'status': 'error'
            })
        }
        
    except psycopg2.Error as e:
        error_msg = f"Database error during restoration: {str(e)}"
        logger.error(error_msg)
        return {
            'statusCode': 500,
            'body': json.dumps({
                'message': error_msg,
                'status': 'error'
            })
        }
        
    except Exception as e:
        error_msg = f"Unexpected error during restoration: {str(e)}"
        logger.error(error_msg)
        return {
            'statusCode': 500,
            'body': json.dumps({
                'message': error_msg,
                'status': 'error'
            })
        }
