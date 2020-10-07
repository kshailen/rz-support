data "aws_caller_identity" "current" {}

locals {
  aws_region     = var.aws_region
  appid_tag      = var.appid_tag
  env_tag        = var.env_tag
  awsaccount_tag = var.awsaccount_tag
  createdby_tag  = var.createdby_tag
  subnet_ids     = var.subnet_ids_list
  vpc_id     =      var.vpc_id
}

module "bki-iam-role-BKI-SR-S3ToSplunk" {
  source                  = "terraform.bkfs.com/BlackKnight/bki-iam-role/aws"
  role_name               = "BKI-SR-S3ToSplunk"
  role_description        = "Provides access to AWS Resources"
  appid_tag = local.appid_tag
  awsaccount_tag = local.awsaccount_tag
  createdby_tag = local.createdby_tag
  env_tag = local.env_tag
  function_tag = "IAM Role for S3ToSplunkHEC Lambdas"
  assume_role_policy_file = "${path.module}/BKI-SR-S3ToSplunk-AssumeRolePolicy.json"
}

module "bki-iam-policy-BKI-SR-S3ToSplunk-ServiceRolePolicy" {
  source             = "terraform.bkfs.com/BlackKnight/bki-iam-policy/aws"
  policy_name        = "BKI-SR-S3ToSplunk-ServiceRolePolicy"
  policy_description = "Service Role Policy for AWS resources"
  policy_file        = "${path.module}/BKI-SR-S3ToSplunk-ServiceRolePolicy.json"
}

module "bki-iam-role-policy-attachment-policies-to-service-role" {
  source    = "terraform.bkfs.com/BlackKnight/bki-iam-role-policy-attachment/aws"
  role_name = "${module.bki-iam-role-BKI-SR-S3ToSplunk.name}"
  arn_list  = [
    "${module.bki-iam-policy-BKI-SR-S3ToSplunk-ServiceRolePolicy.arn}",
  "arn:aws:iam::aws:policy/AmazonS3FullAccess",
  "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",
  "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
  ]
}


module "bki_security_group_s3tosplunk" {
  source  = "terraform.bkfs.com/BlackKnight/bki-security-group/aws"

  appid_tag = local.appid_tag
  awsaccount_tag = local.awsaccount_tag
  createdby_tag = local.createdby_tag
  env_tag = local.env_tag
  function_tag = "Security Group for S3ToSplunkHEC Lambdas"
  group_description = "Security Group for S3ToSplunk Lambda"
  group_name = "bki-${local.awsaccount_tag}-splunkhec-lambda-${local.env_tag}"
  ingress = [{
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/8"]
  }]
  egress =[{
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }]
  vpc_id = local.vpc_id
}

module "kms-key-bki-logging" {
  source  = "terraform.bkfs.com/BlackKnight/bki-kms-key/aws"

  aws_region      = local.aws_region
  name_tag        = "bki/logging"
  appid_tag       = local.appid_tag
  awsaccount_tag  = local.awsaccount_tag
  createdby_tag   = local.createdby_tag
  env_tag         = local.env_tag
  function_tag    = "cloudwatch log group encryption"
  description     = "cloudwatch log group encryption"
  is_enabled      = "true"
  kms_policy_inline = <<EOF
  {
    "Version": "2012-10-17",
    "Id": "key-default-1",
    "Statement": [
        {
            "Sid": "Enable IAM User Permissions",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
            },
            "Action": "kms:*",
            "Resource": "*"
        },
    {
            "Effect": "Allow",
            "Principal": { "Service": "logs.${local.aws_region}.amazonaws.com" },
            "Action": [ 
                "kms:Encrypt*",
                "kms:Decrypt*",
                "kms:ReEncrypt*",
                "kms:GenerateDataKey*",
                "kms:Describe*"
            ],
            "Resource": "*"
        }  
    ]
  }
  EOF
}

resource "aws_kms_alias" "alias" {
  name          = "alias/bki/logging-${local.aws_region}-1"
  target_key_id = module.kms-key-bki-logging.key_id
}

module "bki_lambda_s3LogsProcessor" {
  source  = "./terraform-aws-bki-lambda-without-trigger"

  appid_tag = local.appid_tag
  awsaccount_tag = local.awsaccount_tag
  createdby_tag = local.createdby_tag
  env_tag = local.env_tag
  function_tag = "Send s3 access logs to SplunkHEC"
  notes_tag = "test"
  division_tag = "test"
  application_segment_tag = "test"
  lambda_function_description = "Send s3 access logs to SplunkHEC"
  lambda_function_name = "S3LogsProcessor"
  lambda_handler_name = "index.handler"
  lambda_memory = 128
  lambda_role_arn = "${module.bki-iam-role-BKI-SR-S3ToSplunk.arn}"
  lambda_runtime = "nodejs10.x"
  lambda_source_file_name = "${path.module}/s3logsprocessor.zip"
  lambda_timeout = 30
  #bucketname = 
  lambda_log_retention_days = 14
  env_variables = {
    "SPLUNK_HEC_TOKEN":var.splunk_hec_token_cwlogs,
  "SPLUNK_HEC_URL":var.splunk_hec_url_cwlogs,
  "aws_account_name":var.aws_account_name
  }
  name_tag = "s3LogsProcessor"
  security_group_id = ["${module.bki_security_group_s3tosplunk.id}"]
  kms_key_id = module.kms-key-bki-logging.arn
  vpc_subnet_ids = local.subnet_ids
}

#To add the trigger for S3 Bucket Object creation
resource "aws_s3_bucket_notification" "my-trigger" {
    bucket = var.trigger_bucket_1

    lambda_function {
        lambda_function_arn = "${module.bki_lambda_s3LogsProcessor.arn}"
        events              = ["s3:ObjectCreated:*"]
    }
}

resource "aws_lambda_permission" "test" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = "${module.bki_lambda_s3LogsProcessor.arn}"
  principal = "s3.amazonaws.com"
  source_arn = "arn:aws:s3:::${var.trigger_bucket_1}"
}

#To add the trigger for S3 Bucket Object creation
resource "aws_s3_bucket_notification" "my-trigger-2" {
    bucket = var.trigger_bucket_2

    lambda_function {
        lambda_function_arn = "${module.bki_lambda_s3LogsProcessor.arn}"
        events              = ["s3:ObjectCreated:*"]
    }
}

resource "aws_lambda_permission" "test-2" {
  statement_id  = "AllowS3Invoke-2"
  action        = "lambda:InvokeFunction"
  function_name = "${module.bki_lambda_s3LogsProcessor.arn}"
  principal = "s3.amazonaws.com"
  source_arn = "arn:aws:s3:::${var.trigger_bucket_2}"
}
