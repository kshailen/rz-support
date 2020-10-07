provider "aws" {
  region = "us-east-1"
}

locals {
  aws_region     = "us-east-1"
  appid_tag      = "S00012"
  env_tag        = "sandbox"
  awsaccount_tag = "hopssandbox"
  createdby_tag  = "e1208742@lpsvcs.com"
  vpc_id         = "vpc-0bd58e3d4ca306b38"
  subnet_ids     = ["subnet-009b28feaca15f6d2","subnet-036829b35644cea42","subnet-098b46e33b93d2e0e"]
}

module "terraform-aws-bki-cloudwatch-to-splunk" {
  source  = "./terraform-aws-bki-s3-to-splunk"
  
  aws_region     = local.aws_region
  appid_tag      = local.appid_tag
  awsaccount_tag = local.awsaccount_tag
  createdby_tag  = local.createdby_tag
  env_tag        = local.env_tag
  vpc_id          = local.vpc_id
  subnet_ids_list = local.subnet_ids
}

