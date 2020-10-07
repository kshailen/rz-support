# IAM Role resource creation


## Example resources ##
```
module "roletest1" {
  source      = "./terraform-aws-bki-iam-role"
  role_name   = "BKI-SR-modetest-s3_ingest_lambda_exec"
  role_description = "test inline assume role and policy attachment"
  function_tag                = "ssm-patch-logs"
  appid_tag                   = "A000012"
  env_tag                     = "DEV"
  awsaccount_tag              = "HOpS-DEV"
  createdby_tag	              = "e-number@bkfs.com"
  attach_policies = [
    module.policytest2.arn
  ]
  assume_role_policy_inline   = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": [
            "lambda.amazonaws.com",
            "apigateway.amazonaws.com"
        ]
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

module "roletest2" {
  source      = "./terraform-aws-bki-iam-role"
  role_name   = "bad-name"
  role_description = "test file assume role and missing name prefix"
  assume_role_policy_file = "./assume_policy.json"
}
```