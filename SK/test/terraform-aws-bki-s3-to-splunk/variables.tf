variable "aws_region" {
  type        = string
  description = "The AWS Region"
  default     = null
}

variable "appid_tag" {
  type        = string
  description = "The main AppID using these Lambdas."
}

variable "env_tag" {
  description = "Environment that this parameter will be referenced."
  type        = string
}

variable "awsaccount_tag" {
  description = "Account Name"
  type        = string
}

variable "createdby_tag" {
  description = "e-number@lpsvcs.com"
  type        = string
}

variable "subnet_ids_list" {
  type        = list
  description = "Subnets to attach the lamba to"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "splunk_hec_token_cwlogs" {
  type        = string
  description = "The HEC Token for the CloudWatch Logs indexer."
  default     = "a718eb95-aecc-47e5-803c-cad7591c0e4b"
}

variable "splunk_hec_url_cwlogs" {
  type        = string
  description = "The HEC URL Endpoint for the CloudWatch Logs indexer."
  default     = "https://splunke1-hec-cwlogs.shared-services.awsprodint.site:8088/services/collector"
}

variable "aws_account_name" {
  type        = string
  description = "Name of aws account where Lambda function is getting created"
  default     = "HOpSDEV"
}


variable "trigger_bucket_1" {
  type        = string
  description = "Name of s3 bucket which will have access logs and will act as trigger for invoking lambda function"
  default     = "bki-bki-hopsdev-access-logs-us-east-1"
}


variable "trigger_bucket_2" {
  type        = string
  description = "Name of s3 bucket which will have access logs and will act as trigger for invoking lambda function"
  default     = "bki-bki-hopsdev-access-logs-us-east-2"
}
