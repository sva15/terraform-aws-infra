# IAM policy document for Lambda execution role
data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

# IAM policy document for Lambda execution policy
data "aws_iam_policy_document" "lambda_execution_policy" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = ["arn:aws:logs:*:*:*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "ec2:CreateNetworkInterface",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DeleteNetworkInterface",
      "ec2:AttachNetworkInterface",
      "ec2:DetachNetworkInterface"
    ]

    resources = ["*"]
  }
}

# IAM role for Lambda functions
resource "aws_iam_role" "lambda_execution_role" {
  name               = "${var.iam_role_prefix}-${var.project_short_name}-lambda-execution"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json

  tags = merge(var.common_tags, {
    Name        = "${var.iam_role_prefix}-${var.project_short_name}-lambda-execution"
    Description = "IAM role for Lambda function execution"
    Module      = "backend"
    Service     = "lambda"
  })
}

# IAM policy for Lambda execution
resource "aws_iam_policy" "lambda_execution_policy" {
  name        = "${local.lambda_name_prefix}execution-policy"
  description = "IAM policy for Lambda function execution"
  policy      = data.aws_iam_policy_document.lambda_execution_policy.json

  tags = merge(var.common_tags, {
    Name        = "${local.lambda_name_prefix}execution-policy"
    Description = "IAM policy for Lambda function execution"
    Module      = "backend"
  })
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "lambda_execution_policy" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.lambda_execution_policy.arn
}

# Attach AWS managed VPC execution policy
resource "aws_iam_role_policy_attachment" "lambda_vpc_execution_policy" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}
