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
        region = os.environ.get('AWS_REGION', 'ap-south-1')
        
        if not secret_name:
            raise ValueError("DB_SECRET_NAME environment variable is required when using Secrets Manager")
        
        logger.info(f"Retrieving database credentials from Secrets Manager: {secret_name}")
        secret = get_secret(secret_name, region)
        
        return {
            'host': secret.get('host', os.environ.get('RDS_ENDPOINT')),
            'port': secret.get('port', os.environ.get('RDS_PORT', '5432')),
            'database': secret.get('dbname', os.environ.get('DB_NAME')),
            'username': secret.get('username', os.environ.get('DB_USERNAME')),
            'password': secret['password']
        }
    else:
        # Use environment variables (legacy method)
        logger.info("Using database credentials from environment variables")
        return {
            'host': os.environ.get('RDS_ENDPOINT'),
            'port': os.environ.get('RDS_PORT', '5432'),
            'database': os.environ.get('DB_NAME'),
            'username': os.environ.get('DB_USERNAME'),
            'password': os.environ.get('DB_PASSWORD')
        }

def handler(event, context):
    """
    Lambda function to restore PostgreSQL database from S3 backup
    """
    try:
        # Get database credentials
        db_credentials = get_database_credentials()
        
        # Debug: Log the credentials structure (without password)
        logger.info(f"Retrieved credentials keys: {list(db_credentials.keys())}")
        
        rds_endpoint = db_credentials.get('host')
        rds_port = db_credentials.get('port', '5432')
        db_name = db_credentials.get('database')
        db_username = db_credentials.get('username')
        db_password = db_credentials.get('password')
        s3_bucket = os.environ.get('S3_BUCKET', '')
        s3_key = os.environ.get('S3_KEY', '')
        
        # Debug: Log what we got (without password)
        logger.info(f"Parsed credentials - Host: {rds_endpoint}, Port: {rds_port}, DB: {db_name}, User: {db_username}")
        
        # Validate required credentials
        if not rds_endpoint:
            raise ValueError("RDS endpoint (host) is required but not found in credentials")
        if not db_name:
            raise ValueError("Database name is required but not found in credentials")
        if not db_username:
            raise ValueError("Database username is required but not found in credentials")
        if not db_password:
            raise ValueError("Database password is required but not found in credentials")
        
        # Convert port to integer
        try:
            rds_port = int(rds_port)
        except (ValueError, TypeError):
            logger.warning(f"Invalid port value '{rds_port}', using default 5432")
            rds_port = 5432
        
        logger.info(f"Starting database restoration for {db_name} on {rds_endpoint}:{rds_port}")
        
        # Debug: Log environment info
        logger.info(f"Lambda function environment:")
        logger.info(f"  - AWS_REGION: {os.environ.get('AWS_REGION', 'Not set')}")
        logger.info(f"  - USE_SECRETS_MANAGER: {os.environ.get('USE_SECRETS_MANAGER', 'Not set')}")
        logger.info(f"  - S3_BUCKET: {s3_bucket}")
        logger.info(f"  - S3_KEY: {s3_key}")
        
        # Debug: Check Lambda function configuration
        try:
            lambda_client = boto3.client('lambda')
            function_name = context.function_name if context else 'unknown'
            logger.info(f"Lambda function name: {function_name}")
            
            if context:
                func_config = lambda_client.get_function_configuration(FunctionName=function_name)
                vpc_config = func_config.get('VpcConfig', {})
                logger.info(f"Lambda VPC Config:")
                logger.info(f"  - VpcId: {vpc_config.get('VpcId', 'Not in VPC')}")
                logger.info(f"  - SubnetIds: {vpc_config.get('SubnetIds', [])}")
                logger.info(f"  - SecurityGroupIds: {vpc_config.get('SecurityGroupIds', [])}")
        except Exception as e:
            logger.warning(f"Could not get Lambda configuration: {str(e)}")
        
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
        # RDS endpoint format: db-identifier.random-string.region.rds.amazonaws.com
        try:
            if rds_endpoint and '.' in rds_endpoint:
                db_identifier = rds_endpoint.split('.')[0]
            else:
                # Fallback: try to construct identifier from environment
                db_identifier = os.environ.get('RDS_DB_IDENTIFIER', f"{os.environ.get('PROJECT', 'ifrs')}-db")
                logger.warning(f"Could not parse DB identifier from endpoint '{rds_endpoint}', using fallback: {db_identifier}")
            
            logger.info(f"Using DB identifier: {db_identifier}")
            
            waiter = rds_client.get_waiter('db_instance_available')
            waiter.wait(
                DBInstanceIdentifier=db_identifier,
                WaiterConfig={
                    'Delay': 30,
                    'MaxAttempts': 20
                }
            )
        except Exception as e:
            logger.warning(f"Could not wait for RDS instance: {str(e)}. Proceeding with connection attempt...")
            # Continue without waiting - the connection attempt will fail if RDS is not ready
        
        # Connect to PostgreSQL
        logger.info(f"Connecting to PostgreSQL database at {rds_endpoint}:{rds_port}...")
        
        # Test DNS resolution first
        import socket
        try:
            logger.info(f"Testing DNS resolution for {rds_endpoint}...")
            ip_address = socket.gethostbyname(rds_endpoint)
            logger.info(f"DNS resolution successful: {rds_endpoint} -> {ip_address}")
        except socket.gaierror as e:
            logger.error(f"DNS resolution failed for {rds_endpoint}: {str(e)}")
            logger.error("This usually indicates:")
            logger.error("1. Lambda function is not in the same VPC as RDS")
            logger.error("2. VPC DNS resolution is not enabled")
            logger.error("3. Security groups are blocking access")
            logger.error("4. Subnets don't have proper routing")
            
            # Check if Lambda is in VPC
            if 'AWS_LAMBDA_RUNTIME_API' in os.environ:
                logger.info("Lambda runtime detected")
            
            # Try to get network interface info
            try:
                import subprocess
                result = subprocess.run(['ip', 'addr'], capture_output=True, text=True, timeout=5)
                logger.info(f"Network interfaces: {result.stdout}")
            except:
                logger.info("Could not get network interface information")
            
            raise Exception(f"Cannot resolve RDS hostname {rds_endpoint}. Lambda function may not be in the correct VPC or DNS resolution is not working.")
        
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
