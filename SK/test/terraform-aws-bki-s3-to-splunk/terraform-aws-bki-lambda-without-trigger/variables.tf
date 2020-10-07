variable "aws_region"{
  type        = string
  default     = "us-east-1"
}
variable "lambda_data_archive_file_type" {
  type        = string
  description = "the lambda data archive file type.  Only zip is supported at this time.  Do not specify if you wish to use the raw file (i.e. jars)"
  default     = null
}

variable "enable_xray" {
  type        = string
  description = "Set to true if you wish to enable xray on this lambda function"
  default     = "false"
}

variable "lambda_source_file_name" {
  type        = string
  description = "the lambda source file name"
}

variable "lambda_output_file_name" {
  type        = string
  description = "the lambda output file name if the source file is to be zipped, otherwise ignored"
  default     = null
}

variable "lambda_function_description" {
  type        = string
  description = "the lambda function description"
}

variable "lambda_handler_name" {
  type        = string
  description = "the lambda handler name"
}

variable "lambda_function_name" {
  type        = string
  description = "the lambda function name"
}

variable "security_group_id" {
  type        = list
  description = "List of lambda security group ids"
}

variable "lambda_runtime" {
  type        = string
  description = "the lambda runtime version"
}

variable "lambda_memory" {
  type        = string
  description = "Amount of memory to allocate for the Lambda"
  default     = null
}

variable "lambda_timeout" {
  type        = string
  description = "the lambda timeout"
}

variable "lambda_role_arn" {
  type        = string
  description = "the lambda execution role"
}

#variable "bucketname" {
#  type        = string
#  description = "the lambda execution role"
#}

variable "lambda_log_retention_days" {
  type        = string
  description = "number of days to retain lambda cloudwatch logs"
  default     = 1
}

// A list of VPC subnet identifiers.
variable "vpc_subnet_ids" {
  type        = list
  description = "Subnets to attach the lamba to"
}

variable "name_tag" {
  description = "Name"
  type        = string
}

variable "appid_tag" {
  description = "Identifier for the application using the instance."
  type        = string
}

variable "env_tag" {
  description = "Environment(s) that this parameter will be referenced."
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

variable "function_tag" {
  description = "Function or purpose of the lambda."
  type        = string
  default     = null
}

// more tags if needed
variable "extended_tags" {
  description = "A mapping of tags to assign to the resource"
  type        = map
  default     = {}
}

variable "env_variables" {
  description = "Map of variables to set for the lambda"
  type        = map
  default     = null
}


variable "publish" {
  description = "If this lambda should be published to a new version"
  type        = string
  default     = "false"
}


variable "kms_key_id" {
  description = "Required: ARN of the KMS key use to encrypt log data."
  type = string
}

variable "event_source_arn" {
  description = "Optional: ARN of the event source to trigger function execution"
  type        = string
  default     = null
}

variable "provisioned_concurrent_executions" {
  description = "Optional: the number of function instances to pre-instantiate"
  type        = number
  default     = 0
}

variable "division_tag" {
  type = string
  description = "Examples: Corp, OT, DNA, etc"
}

variable "application_segment_tag" {
  type = string
  description = "Examples: Empower, Compass, Exchange, HOps, TIO, etc"
}

variable "notes_tag" {
  type = string
  description = "location of your support document"
}

variable "concurrent_warning_alarm_enabled" {
  type = bool
  default = false
}


variable "concurrent_warning_threshold" {
  description = "ConcurentExecution"
  type        = number
  default     = 800
}

variable "concurrent_warning_evaluation_periods" {
  type = number
  default = 1
}


variable "concurrent_warning_period" {
  type = number
  default = 300
}

variable "concurrent_warning_alarm_to_spectrum" {
  type = bool
  default = true
}



variable "concurrent_warning_alarm_actions" {
  type = list
  default = []
}


variable "concurrent_warning_ok_to_spectrum" {
  type = bool
  default = true
}

variable "concurrent_warning_ok_actions" {
  type = list
  default = []
}


variable "concurrent_critical_alarm_enabled" {
  type = bool
  default = false
}


variable "concurrent_critical_threshold" {
  description = "ConcurentExecution"
  type        = number
  default     = 900
}



variable "concurrent_critical_evaluation_periods" {
  type = number
  default = 1
}



variable "concurrent_critical_period" {
  type = number
  default = 300
}


variable "concurrent_critical_alarm_to_spectrum" {
  type = bool
  default = true
}


variable "concurrent_critical_alarm_actions" {
  type = list
  default = []
}


variable "concurrent_critical_ok_to_spectrum" {
  type = bool
  default = true
}


variable "concurrent_critical_ok_actions" {
  type = list
  default = []
}

variable "errors_critical_alarm_enabled" {
  type = bool
  default = false
}


variable "errors_critical_threshold" {
  description = "Errors"
  type        = number
  default     = 3
}

variable "errors_critical_evaluation_periods" {
  type = number
  default = 1
}


variable "errors_critical_period" {
  type = number
  default = 300
}

variable "errors_critical_alarm_to_spectrum" {
  type = bool
  default = true
}



variable "errors_critical_alarm_actions" {
  type = list
  default = []
}


variable "errors_critical_ok_to_spectrum" {
  type = bool
  default = true
}

variable "errors_critical_ok_actions" {
  type = list
  default = []
}


variable "errors_warning_alarm_enabled" {
  type = bool
  default = false
}


variable "errors_warning_threshold" {
  description = "Errors"
  type        = number
  default     = 1
}

variable "errors_warning_evaluation_periods" {
  type = number
  default = 1
}


variable "errors_warning_period" {
  type = number
  default = 300
}

variable "errors_warning_alarm_to_spectrum" {
  type = bool
  default = true
}



variable "errors_warning_alarm_actions" {
  type = list
  default = []
}


variable "errors_warning_ok_to_spectrum" {
  type = bool
  default = true
}

variable "errors_warning_ok_actions" {
  type = list
  default = []
}


variable "invocations_critical_alarm_enabled" {
  type = bool
  default = false
}


variable "invocations_critical_threshold" {
  description = "Invocations"
  type        = number
  default     = 1200
}

variable "invocations_critical_evaluation_periods" {
  type = number
  default = 1
}


variable "invocations_critical_period" {
  type = number
  default = 300
}

variable "invocations_critical_alarm_to_spectrum" {
  type = bool
  default = true
}



variable "invocations_critical_alarm_actions" {
  type = list
  default = []
}


variable "invocations_critical_ok_to_spectrum" {
  type = bool
  default = true
}

variable "invocations_critical_ok_actions" {
  type = list
  default = []
}


variable "invocations_warning_alarm_enabled" {
  type = bool
  default = false
}


variable "invocations_warning_threshold" {
  description = "Invocations"
  type        = number
  default     = 1000
}

variable "invocations_warning_evaluation_periods" {
  type = number
  default = 1
}


variable "invocations_warning_period" {
  type = number
  default = 300
}

variable "invocations_warning_alarm_to_spectrum" {
  type = bool
  default = true
}

variable "invocations_warning_alarm_actions" {
  type = list
  default = []
}


variable "invocations_warning_ok_to_spectrum" {
  type = bool
  default = true
}

variable "invocations_warning_ok_actions" {
  type = list
  default = []
}

variable "durations_critical_alarm_enabled" {
  type = bool
  default = false
}


variable "durations_critical_threshold" {
  description = "durations"
  type        = number
  default     = 90000
}

variable "durations_critical_evaluation_periods" {
  type = number
  default = 1
}


variable "durations_critical_period" {
  type = number
  default = 300
}

variable "durations_critical_alarm_to_spectrum" {
  type = bool
  default = true
}



variable "durations_critical_alarm_actions" {
  type = list
  default = []
}


variable "durations_critical_ok_to_spectrum" {
  type = bool
  default = true
}

variable "durations_critical_ok_actions" {
  type = list
  default = []
}


variable "durations_warning_alarm_enabled" {
  type = bool
  default = false
}


variable "durations_warning_threshold" {
  description = "durations"
  type        = number
  default     = 72000
}

variable "durations_warning_evaluation_periods" {
  type = number
  default = 1
}


variable "durations_warning_period" {
  type = number
  default = 300
}

variable "durations_warning_alarm_to_spectrum" {
  type = bool
  default = true
}

variable "durations_warning_alarm_actions" {
  type = list
  default = []
}


variable "durations_warning_ok_to_spectrum" {
  type = bool
  default = true
}

variable "durations_warning_ok_actions" {
  type = list
  default = []
}

variable "throttles_critical_alarm_enabled" {
  type = bool
  default = false
}


variable "throttles_critical_threshold" {
  description = "throttles"
  type        = number
  default     = 3
}

variable "throttles_critical_evaluation_periods" {
  type = number
  default = 1
}


variable "throttles_critical_period" {
  type = number
  default = 300
}

variable "throttles_critical_alarm_to_spectrum" {
  type = bool
  default = true
}



variable "throttles_critical_alarm_actions" {
  type = list
  default = []
}


variable "throttles_critical_ok_to_spectrum" {
  type = bool
  default = true
}

variable "throttles_critical_ok_actions" {
  type = list
  default = []
}


variable "throttles_warning_alarm_enabled" {
  type = bool
  default = false
}


variable "throttles_warning_threshold" {
  description = "throttles"
  type        = number
  default     = 2
}

variable "throttles_warning_evaluation_periods" {
  type = number
  default = 1
}


variable "throttles_warning_period" {
  type = number
  default = 300
}

variable "throttles_warning_alarm_to_spectrum" {
  type = bool
  default = true
}

variable "throttles_warning_alarm_actions" {
  type = list
  default = []
}


variable "throttles_warning_ok_to_spectrum" {
  type = bool
  default = true
}

variable "throttles_warning_ok_actions" {
  type = list
  default = []
}










