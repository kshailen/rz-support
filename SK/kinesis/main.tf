provider "aws" {
  region     = "us-east-1"
}
resource "aws_s3_bucket" "bucket" {
  bucket = var.s3_bucket_name
  acl    = "private"
}




module "kinesis_iam" {
  source      = "./terraform-aws-bki-iam-role-master"
  role_name   = var.kinesis_firehose_role_name
  role_description = "This role is for kinesis firehouse"
  function_tag                = "ssm-patch-logs"
  appid_tag                   = "A000012"
  env_tag                     = "DEV"
  awsaccount_tag              = "HOpS-DEV"
  createdby_tag               = "lc1209472@bkfs.com"
  assume_role_policy_inline   = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "firehose.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

module "lambda_iam" {
  source      = "./terraform-aws-bki-iam-role-master"
  role_name   = "var.kinesis_firehose_lambda_role_name"
  role_description = "This role is for kinesis firehouse Lambda function"
  function_tag                = "ssm-patch-logs"
  appid_tag                   = "A000012"
  env_tag                     = "DEV"
  awsaccount_tag              = "HOpS-DEV"
  createdby_tag               = "lc1209472@bkfs.com"
  assume_role_policy_inline   = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}


resource "aws_lambda_function" "lambda_processor" {
  filename      = "kinesis.zip"
  function_name = var.lambda_function_name
  role          = module.lambda_iam.arn
  handler       = "kinesis.handler"
  runtime       = "python2.7"
  environment {
    variables = {
      SPLUNK_SOURCETYPE = "aws:cloudwatch"
    }
  }
}



resource "aws_kinesis_firehose_delivery_stream" "test_stream" {
  name        = var.firehose_name
  destination = "splunk"

  s3_configuration {
    role_arn           = module.kinesis_iam.arn
    bucket_arn         = "${aws_s3_bucket.bucket.arn}"
    buffer_size        = var.kinesis_firehose_buffer
    buffer_interval    = var.kinesis_firehose_buffer_interval
    compression_format = var.s3_compression_format
  }

  splunk_configuration {
    hec_endpoint               = var.hec_url
    hec_token                  = "a718eb95-aecc-47e5-803c-cad7591c0e4b"
    hec_acknowledgment_timeout = var.hec_acknowledgment_timeout
    hec_endpoint_type          = var.hec_endpoint_type
    s3_backup_mode             = var.s3_backup_mode
      processing_configuration {
      enabled = "true"

      processors {
        type = "Lambda"

        parameters {
          parameter_name  = "LambdaArn"
          parameter_value = "${aws_lambda_function.lambda_processor.arn}:$LATEST"
        }
        parameters {
          parameter_name  = "RoleArn"
          parameter_value = module.kinesis_iam.arn
        }
      }
    }
    cloudwatch_logging_options {
      enabled         = var.enable_fh_cloudwatch_logging
      log_group_name  = aws_cloudwatch_log_group.kinesis_logs.name
      log_stream_name = aws_cloudwatch_log_stream.kinesis_logs.name
    }
  }


}


# Cloudwatch logging group for Kinesis Firehose
resource "aws_cloudwatch_log_group" "kinesis_logs" {
  name              = "/aws/kinesisfirehose/${var.firehose_name}"
  retention_in_days = var.cloudwatch_log_retention

}

# Create the stream
resource "aws_cloudwatch_log_stream" "kinesis_logs" {
  name           = var.log_stream_name
  log_group_name = aws_cloudwatch_log_group.kinesis_logs.name
}


module "cloudwatch_to_firehose_trust" {
  source      = "./terraform-aws-bki-iam-role-master"
  role_name   = var.cloudwatch_to_firehose_trust_iam_role_name
  role_description = "This role is for kinesis firehouse CWL Trust"
  function_tag                = "ssm-patch-logs"
  appid_tag                   = "A000012"
  env_tag                     = "DEV"
  awsaccount_tag              = "HOpS-DEV"
  createdby_tag               = "lc1209472@bkfs.com"
  assume_role_policy_inline   = <<EOF
{
    "Statement": [
    {
      "Effect": "Allow",
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "logs.us-east-1.amazonaws.com"
      }
    }
  ],
  "Version": "2012-10-17"
}
EOF
}


data "aws_iam_policy_document" "cloudwatch_to_fh_access_policy" {
  statement {
    actions = [
      "firehose:*",
    ]

    effect = "Allow"

    resources = [
      aws_kinesis_firehose_delivery_stream.test_stream.arn,
    ]
  }

  statement {
    actions = [
      "iam:PassRole",
    ]

    effect = "Allow"

    resources = [
      module.cloudwatch_to_firehose_trust.arn,
    ]
  }
}




module "cloudwatch_to_fh_access_policy" {
  source      = "./terraform-aws-bki-iam-policy"
  policy_name = "BKI-SR-cloudwatch_to_fh_access_policy"
  policy_description = "Testing inline policy creation with role attachment"
  attach_roles = [
      module.cloudwatch_to_firehose_trust.name
  ]
  inline_policy = data.aws_iam_policy_document.cloudwatch_to_fh_access_policy.json
}


resource "aws_cloudwatch_log_subscription_filter" "cloudwatch_log_filter" {
  name            = var.cloudwatch_log_filter_name
  role_arn        = module.cloudwatch_to_firehose_trust.arn
  destination_arn = aws_kinesis_firehose_delivery_stream.test_stream.arn
  log_group_name  = var.name_cloudwatch_logs_to_ship
  filter_pattern  = var.subscription_filter_pattern
}