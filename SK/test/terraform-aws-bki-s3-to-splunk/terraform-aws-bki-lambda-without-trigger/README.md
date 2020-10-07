# Lambda module

## Example usage
```
module "lambdarefactor" {
  source                        = "./terraform-aws-bki-lambda"
  lambda_function_name          = "BKI-RefactorTest1_Rizwan"
  lambda_source_file_name       = "lambda_function.zip"
  lambda_function_description   = "Lambda module testing"
  lambda_handler_name           = "com.bkfs.hops.dev.LambdaRetrofit::retrofit_lambda_handler"
  lambda_runtime                = "python3.7"
  lambda_memory                 = 128
  lambda_timeout                = 30
  lambda_role_arn               = "arn:aws:iam::574029749308:role/BKI-SR-LambdaTest"
  vpc_subnet_ids                = ["subnet-009b28feaca15f6d2"]
  security_group_id             = ["sg-017e095942a8f0f04"]
  kms_key_id                    = "arn:aws:kms:us-east-1:574029749308:key/700b6c7d-ce7e-46b5-ad28-6efb3c71bcd9"
  name_tag                      = "LambdaRefactor1"
  appid_tag                     = "S00012"
  env_tag                       = "dev"
  awsaccount_tag                = "testing lambda mods"
  createdby_tag                 = "e1207205"
  function_tag                  = "module testing for default output name"
}



module "lambdarefactor_1" {
  source                        = "./terraform-aws-bki-lambda"
  lambda_function_name          = "BKI-RefactorTest1_Rizwan_1"
  lambda_source_file_name       = "lambda_function.zip"
  lambda_function_description   = "Lambda module testing"
  lambda_handler_name           = "com.bkfs.hops.dev.LambdaRetrofit::retrofit_lambda_handler"
  lambda_runtime                = "python3.7"
  lambda_memory                 = 128
  lambda_timeout                = 30
  lambda_role_arn               = "arn:aws:iam::574029749308:role/BKI-SR-LambdaTest"
  vpc_subnet_ids                = ["subnet-009b28feaca15f6d2"]
  security_group_id             = ["sg-017e095942a8f0f04"]
  kms_key_id                    = "arn:aws:kms:us-east-1:574029749308:key/700b6c7d-ce7e-46b5-ad28-6efb3c71bcd9"
  name_tag                      = "LambdaRefactor1"
  appid_tag                     = "S00012"
  env_tag                       = "dev"
  awsaccount_tag                = "testing lambda mods"
  createdby_tag                 = "e1207205"
  function_tag                  = "module testing for default output name"
  concurrent_warning_alarm_enabled = "false"
  concurrent_critical_alarm_enabled = "false"
  errors_critical_alarm_enabled = "false"
  errors_warning_alarm_enabled = "false"
  invocations_critical_alarm_enabled = "false"
  invocations_warning_alarm_enabled = "false"
  durations_critical_alarm_enabled = "false"
  durations_warning_alarm_enabled = "false"
  throttles_critical_alarm_enabled = "false"
  throttles_warning_alarm_enabled = "false"
}
