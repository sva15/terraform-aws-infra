locals {
  # Environment prefix for naming
  env_prefix = var.environment == "prod" ? "" : "${var.environment}-"

  # Key pair name
  key_pair_name = var.key_pair_name != "" ? var.key_pair_name : "${local.env_prefix}${var.project_name}-ui-keypair"
}

# Data source for AMI (only if ami_id is not provided)
data "aws_ami" "selected" {
  count       = var.ami_id == "" ? 1 : 0
  most_recent = true
  owners      = [var.ami_owner]

  filter {
    name   = "name"
    values = [var.ami_name_pattern]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Generate TLS private key for EC2 key pair
resource "tls_private_key" "ec2_key" {
  count     = var.create_key_pair ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create EC2 key pair
resource "aws_key_pair" "ec2_key_pair" {
  count      = var.create_key_pair ? 1 : 0
  key_name   = local.key_pair_name
  public_key = tls_private_key.ec2_key[0].public_key_openssh

  tags = merge(var.common_tags, {
    Name   = local.key_pair_name
    Module = "ec2"
  })
}

# Save private key to local file
resource "local_file" "private_key" {
  count    = var.create_key_pair ? 1 : 0
  content  = tls_private_key.ec2_key[0].private_key_pem
  filename = "${local.key_pair_name}.pem"

  provisioner "local-exec" {
    command = "chmod 400 ${local.key_pair_name}.pem"
  }
}

# IAM role for EC2 instance
resource "aws_iam_role" "ec2_role" {
  name = "HCL-User-Role-insightgen-ec2-ui"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.common_tags, {
    Name    = "HCL-User-Role-insightgen-ec2-ui"
    Module  = "ec2"
    Service = "ec2-ui"
  })
}

# IAM policy for S3 and ECR access
resource "aws_iam_role_policy" "ec2_policy" {
  name = "${local.env_prefix}${var.project_name}-ui-ec2-policy"
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.ui_s3_bucket}",
          "arn:aws:s3:::${var.ui_s3_bucket}/*"
        ]
      }
    ]
  })
}

# IAM instance profile
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${local.env_prefix}${var.project_name}-ui-ec2-profile"
  role = aws_iam_role.ec2_role.name

  tags = merge(var.common_tags, {
    Name   = "${local.env_prefix}${var.project_name}-ui-ec2-profile"
    Module = "ec2"
  })
}

# User data script for EC2 instance
locals {
  user_data = base64encode(templatefile("${path.module}/user-data.sh", {
    s3_bucket             = var.ui_s3_bucket
    s3_key                = var.ui_s3_key
    ui_path               = var.ui_path
    BASE_URL              = var.BASE_URL
    aws_region            = data.aws_region.current.name
    deploy_database       = var.deploy_database
    postgres_db_name      = var.postgres_db_name
    postgres_user         = var.postgres_user
    postgres_password     = var.postgres_password
    pgadmin_email         = var.pgadmin_email
    pgadmin_password      = var.pgadmin_password
    postgres_port         = var.postgres_port
    pgadmin_port          = var.pgadmin_port
    sql_backup_s3_bucket  = var.sql_backup_s3_bucket
    sql_backup_s3_key     = var.sql_backup_s3_key
    sql_backup_local_path = var.sql_backup_local_path
  }))
}

# Data source for current region
data "aws_region" "current" {}

# EC2 Instance
resource "aws_instance" "ui_server" {
  ami                         = var.ami_id != "" ? var.ami_id : data.aws_ami.selected[0].id
  instance_type               = var.instance_type
  key_name                    = var.create_key_pair ? aws_key_pair.ec2_key_pair[0].key_name : var.key_pair_name
  vpc_security_group_ids      = var.security_group_ids
  subnet_id                   = var.subnet_id
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name
  associate_public_ip_address = true

  user_data = local.user_data

  root_block_device {
    volume_type = "gp3"
    volume_size = 20
    encrypted   = true

    tags = merge(var.common_tags, {
      Name   = "${local.env_prefix}${var.project_name}-ui-server-root"
      Module = "ec2"
    })
  }

  tags = merge(var.common_tags, {
    Name        = "${local.env_prefix}${var.project_name}-ui-server"
    Description = "EC2 instance for UI application"
    Module      = "ec2"
  })

  lifecycle {
    create_before_destroy = true
  }
}
