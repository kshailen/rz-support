# terraform-aws-bki-cloudwatch-to-splunk

```
provider "aws" {
  region = "us-east-1"
}

locals {
  aws_region     = "us-east-1"
  appid_tag      = "S00012"
  env_tag        = "sandbox"
  awsaccount_tag = "hopssandbox"
  createdby_tag  = "e1208742@lpsvcs.com"
  vpc_id         = "vpc-0d32527a4e5624f63"
  subnet_ids     = ["subnet-010e561503d451676","subnet-03f38ead153bc6f13","subnet-039332def4bd42601"]
}

module "terraform-aws-bki-cloudwatch-to-splunk" {
  source  = "../terraform-aws-bki-cloudwatch-to-splunk"
  
  aws_region     = local.aws_region
  appid_tag      = local.appid_tag
  awsaccount_tag = local.awsaccount_tag
  createdby_tag  = local.createdby_tag
  env_tag        = local.env_tag
  vpc_id          = local.vpc_id
  subnet_ids_list = local.subnet_ids
}
```