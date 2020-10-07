data "aws_caller_identity" "current" {}

locals {
  spectrumEnv = data.aws_caller_identity.current.account_id
}


locals {
  output_file = var.lambda_output_file_name == null ? "lambda.zip" : var.lambda_output_file_name
  lambda_src  = var.lambda_data_archive_file_type != "zip" ? var.lambda_source_file_name : local.output_file
  func_tag    = var.function_tag == null ? var.lambda_function_description : var.function_tag
}

data "archive_file" "lambda_archive_file_name" {
  count       = var.lambda_data_archive_file_type == "zip" ? 1 : 0
  type        = var.lambda_data_archive_file_type
  source_file = var.lambda_source_file_name
  output_path = local.output_file
}

resource "aws_cloudwatch_log_group" "cloudwatch_log_group" {
  count             = var.lambda_log_retention_days != null ? 1 : 0
  name              = "/aws/lambda/var.lambda_function_name"
  retention_in_days = var.lambda_log_retention_days
  kms_key_id        = var.kms_key_id
  tags = merge(
    var.extended_tags,
    {
      "Name"       = var.name_tag
      "appid"      = var.appid_tag
      "env"        = var.env_tag
      "awsaccount" = var.awsaccount_tag
      "createdby"  = var.createdby_tag
      "function"   = local.func_tag
    }
  )
}

resource "aws_lambda_function" "lambda_function_name" {
  depends_on = [aws_cloudwatch_log_group.cloudwatch_log_group]

  filename         = local.lambda_src
  description      = var.lambda_function_description
  function_name    = var.lambda_function_name
  role             = var.lambda_role_arn
  handler          = var.lambda_handler_name
  source_code_hash = filebase64sha256("${local.lambda_src}")
  runtime          = var.lambda_runtime
  memory_size      = var.lambda_memory
  timeout          = var.lambda_timeout
  publish          = var.provisioned_concurrent_executions > 0 ? "true" : var.publish

  dynamic "tracing_config" {
    for_each = var.enable_xray == "true" ? ["1"] : []
    content {
      mode = "Active"
    }
  }
  dynamic "environment" {
    for_each = var.env_variables != null ? ["1"] : []
    content {
      variables = var.env_variables
    }
  }
  vpc_config {
    subnet_ids         = var.vpc_subnet_ids
    security_group_ids = var.security_group_id
  }
  tags = merge(
    var.extended_tags,
    {
      "Name"       = var.name_tag
      "appid"      = var.appid_tag
      "env"        = var.env_tag
      "awsaccount" = var.awsaccount_tag
      "createdby"  = var.createdby_tag
      "function"   = local.func_tag
    }
  )
}


data "aws_arn" "iam_role_name" {
  arn = var.lambda_role_arn
}

data "aws_iam_policy" "aws_xray_write_only_access" {
  count = var.enable_xray == "true" ? 1 : 0
  arn   = "arn:aws:iam::aws:policy/AWSXrayWriteOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "lambda_xray" {
  count      = var.enable_xray == "true" ? 1 : 0
  role       = replace(data.aws_arn.iam_role_name.resource, "role/", "")
  policy_arn = data.aws_iam_policy.aws_xray_write_only_access[0].arn
}

resource "aws_lambda_event_source_mapping" "lambda_event_source" {
  count            = var.event_source_arn == null ? 0 : 1
  event_source_arn = var.event_source_arn
  function_name    = aws_lambda_function.lambda_function_name.arn
}

resource "aws_lambda_provisioned_concurrency_config" "lambda_prov_conc" {
  count                             = var.provisioned_concurrent_executions > 0 ? 1 : 0
  function_name                     = aws_lambda_function.lambda_function_name.function_name
  provisioned_concurrent_executions = var.provisioned_concurrent_executions
  qualifier                         = aws_lambda_function.lambda_function_name.version
}



resource "aws_cloudwatch_metric_alarm" "concurrent_critical" {
  count = var.concurrent_critical_alarm_enabled == true ? 1 : 0 
  #Check Alarm Name is fine
  alarm_name = "bki-cw-concurrentAlarmCritical-${data.aws_caller_identity.current.account_id}-${var.lambda_function_name}"
  alarm_description   = "Conurrent Execution High for ${var.concurrent_critical_threshold}  over ${var.concurrent_critical_period} secs"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.concurrent_critical_evaluation_periods
  threshold           = var.concurrent_critical_threshold
  period              = var.concurrent_critical_period

  namespace   = "AWS/Lambda"
  metric_name = "ConcurrentExecutions"
  statistic   = "Sum"

  dimensions = {
    FunctionName  = aws_lambda_function.lambda_function_name.function_name
    Resource = aws_lambda_function.lambda_function_name.function_name
  }

  alarm_actions = var.concurrent_critical_alarm_to_spectrum == true ? concat([
    "arn:aws:sns:${var.aws_region}:${local.spectrumEnv}:bki-spectrum-custom-alarm-metadata"
  ], var.concurrent_critical_alarm_actions) : var.concurrent_critical_alarm_actions
  
  ok_actions = var.concurrent_critical_ok_to_spectrum == true ? concat([
    "arn:aws:sns:${var.aws_region}:${local.spectrumEnv}:bki-spectrum-custom-alarm-metadata"
  ], var.concurrent_critical_ok_actions) : var.concurrent_critical_ok_actions

  tags = {
      Name       = "bki-cw-concurrentAlarmCritical-${data.aws_caller_identity.current.account_id}-${var.lambda_function_name}"
      appid      = var.appid_tag
      env        = var.env_tag
      awsaccount = var.awsaccount_tag
      createdby  = var.createdby_tag
      function   = "Conurrent Execution High for ${var.concurrent_critical_threshold}  over ${var.concurrent_critical_period} secs"
      Severity           = "Critical"
      Division           = var.division_tag
      ApplicationSegment = var.application_segment_tag
      Environment        = var.env_tag
      Notes              = var.notes_tag
    }
}

resource "aws_cloudwatch_metric_alarm" "concurrent_warning" {
  count = var.concurrent_warning_alarm_enabled == true ? 1 : 0 
  alarm_name = "bki-cw-concurrentAlarmWarning-${data.aws_caller_identity.current.account_id}-${var.lambda_function_name}"
  alarm_description   = "Conurrent Execution High for ${var.concurrent_warning_threshold}  over ${var.concurrent_warning_period} secs"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.concurrent_warning_evaluation_periods
  threshold           = var.concurrent_warning_threshold
  period              = var.concurrent_warning_period

  namespace   = "AWS/Lambda"
  metric_name = "ConcurrentExecutions"
  statistic   = "Sum"

  dimensions = {
    FunctionName  = aws_lambda_function.lambda_function_name.function_name
    Resource = aws_lambda_function.lambda_function_name.function_name
  }

  alarm_actions = var.concurrent_warning_alarm_to_spectrum == true ? concat([
    "arn:aws:sns:${var.aws_region}:${local.spectrumEnv}:bki-spectrum-custom-alarm-metadata"
  ], var.concurrent_warning_alarm_actions) : var.concurrent_warning_alarm_actions
  
  ok_actions = var.concurrent_warning_ok_to_spectrum == true ? concat([
    "arn:aws:sns:${var.aws_region}:${local.spectrumEnv}:bki-spectrum-custom-alarm-metadata"
  ], var.concurrent_warning_ok_actions) : var.concurrent_warning_ok_actions

  tags = {
      Name       = "bki-cw-concurrentAlarmWarning-${data.aws_caller_identity.current.account_id}-${var.lambda_function_name}"
      appid      = var.appid_tag
      env        = var.env_tag
      awsaccount = var.awsaccount_tag
      createdby  = var.createdby_tag
      function   = "Conurrent Execution High for ${var.concurrent_warning_threshold}  over ${var.concurrent_warning_period} secs"
      Severity           = "Minor"
      Division           = var.division_tag
      ApplicationSegment = var.application_segment_tag
      Environment        = var.env_tag
      Notes              = var.notes_tag
    }
}


resource "aws_cloudwatch_metric_alarm" "errors_critical" {
  count = var.errors_critical_alarm_enabled == true ? 1 : 0 
  #Check Alarm Name is fine
  alarm_name = "bki-cw-errorsAlarmCritical-${data.aws_caller_identity.current.account_id}-${var.lambda_function_name}"
  alarm_description   = "Errors High for ${var.errors_critical_threshold}  over ${var.errors_critical_period} secs"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.errors_critical_evaluation_periods
  threshold           = var.errors_critical_threshold
  period              = var.errors_critical_period

  namespace   = "AWS/Lambda"
  metric_name = "Errors"
  statistic   = "Sum"

  dimensions = {
    FunctionName  = aws_lambda_function.lambda_function_name.function_name
    Resource = aws_lambda_function.lambda_function_name.function_name
  }

  alarm_actions = var.errors_critical_alarm_to_spectrum == true ? concat([
    "arn:aws:sns:${var.aws_region}:${local.spectrumEnv}:bki-spectrum-custom-alarm-metadata"
  ], var.errors_critical_alarm_actions) : var.errors_critical_alarm_actions
  
  ok_actions = var.errors_critical_ok_to_spectrum == true ? concat([
    "arn:aws:sns:${var.aws_region}:${local.spectrumEnv}:bki-spectrum-custom-alarm-metadata"
  ], var.errors_critical_ok_actions) : var.errors_critical_ok_actions

  tags = {
      Name       = "bki-cw-errorsAlarmCritical-${data.aws_caller_identity.current.account_id}-${var.lambda_function_name}"
      appid      = var.appid_tag
      env        = var.env_tag
      awsaccount = var.awsaccount_tag
      createdby  = var.createdby_tag
      function   = "Errors High for ${var.errors_critical_threshold}  over ${var.errors_critical_period} secs"
      Severity           = "Critical"
      Division           = var.division_tag
      ApplicationSegment = var.application_segment_tag
      Environment        = var.env_tag
      Notes              = var.notes_tag
    }
}

resource "aws_cloudwatch_metric_alarm" "errors_warning" {
  count = var.errors_warning_alarm_enabled == true ? 1 : 0 
  alarm_name = "bki-cw-errorsAlarmWarning-${data.aws_caller_identity.current.account_id}-${var.lambda_function_name}"
  alarm_description   = "Errors High for ${var.errors_warning_threshold}  over ${var.errors_warning_period} secs"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.errors_warning_evaluation_periods
  threshold           = var.errors_warning_threshold
  period              = var.errors_warning_period

  namespace   = "AWS/Lambda"
  metric_name = "Errors"
  statistic   = "Sum"

  dimensions = {
    FunctionName  = aws_lambda_function.lambda_function_name.function_name
    Resource = aws_lambda_function.lambda_function_name.function_name
  }

  alarm_actions = var.errors_warning_alarm_to_spectrum == true ? concat([
    "arn:aws:sns:${var.aws_region}:${local.spectrumEnv}:bki-spectrum-custom-alarm-metadata"
  ], var.errors_warning_alarm_actions) : var.errors_warning_alarm_actions
  
  ok_actions = var.errors_warning_ok_to_spectrum == true ? concat([
    "arn:aws:sns:${var.aws_region}:${local.spectrumEnv}:bki-spectrum-custom-alarm-metadata"
  ], var.errors_warning_ok_actions) : var.errors_warning_ok_actions

  tags = {
      Name       = "bki-cw-errorsAlarmWarning-${data.aws_caller_identity.current.account_id}-${var.lambda_function_name}"
      appid      = var.appid_tag
      env        = var.env_tag
      awsaccount = var.awsaccount_tag
      createdby  = var.createdby_tag
      function   = "Errors High for ${var.errors_warning_threshold}  over ${var.errors_warning_period} secs"
      Severity           = "Minor"
      Division           = var.division_tag
      ApplicationSegment = var.application_segment_tag
      Environment        = var.env_tag
      Notes              = var.notes_tag
    }
}



resource "aws_cloudwatch_metric_alarm" "invocations_critical" {
  count = var.invocations_critical_alarm_enabled == true ? 1 : 0 
  #Check Alarm Name is fine
  alarm_name = "bki-cw-invocationsAlarmCritical-${data.aws_caller_identity.current.account_id}-${var.lambda_function_name}"
  alarm_description   = "Invocations High for ${var.invocations_critical_threshold}  over ${var.invocations_critical_period} secs"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.invocations_critical_evaluation_periods
  threshold           = var.invocations_critical_threshold
  period              = var.invocations_critical_period

  namespace   = "AWS/Lambda"
  metric_name = "Invocations"
  statistic   = "Sum"

  dimensions = {
    FunctionName  = aws_lambda_function.lambda_function_name.function_name
    Resource = aws_lambda_function.lambda_function_name.function_name
  }

  alarm_actions = var.invocations_critical_alarm_to_spectrum == true ? concat([
    "arn:aws:sns:${var.aws_region}:${local.spectrumEnv}:bki-spectrum-custom-alarm-metadata"
  ], var.invocations_critical_alarm_actions) : var.invocations_critical_alarm_actions
  
  ok_actions = var.invocations_critical_ok_to_spectrum == true ? concat([
    "arn:aws:sns:${var.aws_region}:${local.spectrumEnv}:bki-spectrum-custom-alarm-metadata"
  ], var.invocations_critical_ok_actions) : var.invocations_critical_ok_actions

  tags = {
      Name       = "bki-cw-invocationsAlarmCritical-${data.aws_caller_identity.current.account_id}-${var.lambda_function_name}"
      appid      = var.appid_tag
      env        = var.env_tag
      awsaccount = var.awsaccount_tag
      createdby  = var.createdby_tag
      function   = "Invocations High for ${var.invocations_critical_threshold}  over ${var.invocations_critical_period} secs"
      Severity           = "Critical"
      Division           = var.division_tag
      ApplicationSegment = var.application_segment_tag
      Environment        = var.env_tag
      Notes              = var.notes_tag
    }
}

resource "aws_cloudwatch_metric_alarm" "invocations_warning" {
  count = var.invocations_warning_alarm_enabled == true ? 1 : 0 
  alarm_name = "bki-cw-invocationsAlarmWarning-${data.aws_caller_identity.current.account_id}-${var.lambda_function_name}"
  alarm_description   = "Invocations High for ${var.invocations_warning_threshold}  over ${var.invocations_warning_period} secs"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.invocations_warning_evaluation_periods
  threshold           = var.invocations_warning_threshold
  period              = var.invocations_warning_period

  namespace   = "AWS/Lambda"
  metric_name = "Invocations"
  statistic   = "Sum"

  dimensions = {
    FunctionName  = aws_lambda_function.lambda_function_name.function_name
    Resource = aws_lambda_function.lambda_function_name.function_name
  }

  alarm_actions = var.invocations_warning_alarm_to_spectrum == true ? concat([
    "arn:aws:sns:${var.aws_region}:${local.spectrumEnv}:bki-spectrum-custom-alarm-metadata"
  ], var.invocations_warning_alarm_actions) : var.invocations_warning_alarm_actions
  
  ok_actions = var.invocations_warning_ok_to_spectrum == true ? concat([
    "arn:aws:sns:${var.aws_region}:${local.spectrumEnv}:bki-spectrum-custom-alarm-metadata"
  ], var.invocations_warning_ok_actions) : var.invocations_warning_ok_actions

  tags = {
      Name       = "bki-cw-invocationsAlarmWarning-${data.aws_caller_identity.current.account_id}-${var.lambda_function_name}"
      appid      = var.appid_tag
      env        = var.env_tag
      awsaccount = var.awsaccount_tag
      createdby  = var.createdby_tag
      function   = "Invocations High for ${var.invocations_warning_threshold}  over ${var.invocations_warning_period} secs"
      Severity           = "Minor"
      Division           = var.division_tag
      ApplicationSegment = var.application_segment_tag
      Environment        = var.env_tag
      Notes              = var.notes_tag
    }
}


resource "aws_cloudwatch_metric_alarm" "durations_critical" {
  count = var.durations_critical_alarm_enabled == true ? 1 : 0 
  #Check Alarm Name is fine
  alarm_name = "bki-cw-durationsAlarmCritical-${data.aws_caller_identity.current.account_id}-${var.lambda_function_name}"
  alarm_description   = "Durations High for ${var.durations_critical_threshold}  over ${var.durations_critical_period} secs"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.durations_critical_evaluation_periods
  threshold           = var.durations_critical_threshold
  period              = var.durations_critical_period

  namespace   = "AWS/Lambda"
  metric_name = "Durations"
  statistic   = "Average"

  dimensions = {
    FunctionName  = aws_lambda_function.lambda_function_name.function_name
    Resource = aws_lambda_function.lambda_function_name.function_name
  }

  alarm_actions = var.durations_critical_alarm_to_spectrum == true ? concat([
    "arn:aws:sns:${var.aws_region}:${local.spectrumEnv}:bki-spectrum-custom-alarm-metadata"
  ], var.durations_critical_alarm_actions) : var.durations_critical_alarm_actions
  
  ok_actions = var.durations_critical_ok_to_spectrum == true ? concat([
    "arn:aws:sns:${var.aws_region}:${local.spectrumEnv}:bki-spectrum-custom-alarm-metadata"
  ], var.durations_critical_ok_actions) : var.durations_critical_ok_actions

  tags = {
      Name       = "bki-cw-durationsAlarmCritical-${data.aws_caller_identity.current.account_id}-${var.lambda_function_name}"
      appid      = var.appid_tag
      env        = var.env_tag
      awsaccount = var.awsaccount_tag
      createdby  = var.createdby_tag
      function   = "Durations High for ${var.durations_critical_threshold}  over ${var.durations_critical_period} secs"
      Severity           = "Critical"
      Division           = var.division_tag
      ApplicationSegment = var.application_segment_tag
      Environment        = var.env_tag
      Notes              = var.notes_tag
    }
}

resource "aws_cloudwatch_metric_alarm" "durations_warning" {
  count = var.durations_warning_alarm_enabled == true ? 1 : 0 
  alarm_name = "bki-cw-durationsAlarmWarning-${data.aws_caller_identity.current.account_id}-${var.lambda_function_name}"
  alarm_description   = "Durations High for ${var.durations_warning_threshold}  over ${var.durations_warning_period} secs"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.durations_warning_evaluation_periods
  threshold           = var.durations_warning_threshold
  period              = var.durations_warning_period

  namespace   = "AWS/Lambda"
  metric_name = "Durations"
  statistic   = "Average"

  dimensions = {
    FunctionName  = aws_lambda_function.lambda_function_name.function_name
    Resource = aws_lambda_function.lambda_function_name.function_name
  }

  alarm_actions = var.durations_warning_alarm_to_spectrum == true ? concat([
    "arn:aws:sns:${var.aws_region}:${local.spectrumEnv}:bki-spectrum-custom-alarm-metadata"
  ], var.durations_warning_alarm_actions) : var.durations_warning_alarm_actions
  
  ok_actions = var.durations_warning_ok_to_spectrum == true ? concat([
    "arn:aws:sns:${var.aws_region}:${local.spectrumEnv}:bki-spectrum-custom-alarm-metadata"
  ], var.durations_warning_ok_actions) : var.durations_warning_ok_actions

  tags = {
      Name       = "bki-cw-durationsAlarmWarning-${data.aws_caller_identity.current.account_id}-${var.lambda_function_name}"
      appid      = var.appid_tag
      env        = var.env_tag
      awsaccount = var.awsaccount_tag
      createdby  = var.createdby_tag
      function   = "Durations High for ${var.invocations_warning_threshold}  over ${var.invocations_warning_period} secs"
      Severity           = "Minor"
      Division           = var.division_tag
      ApplicationSegment = var.application_segment_tag
      Environment        = var.env_tag
      Notes              = var.notes_tag
    }
}


resource "aws_cloudwatch_metric_alarm" "throttles_critical" {
  count = var.throttles_critical_alarm_enabled == true ? 1 : 0 
  #Check Alarm Name is fine
  alarm_name = "bki-cw-throttlesAlarmCritical-${data.aws_caller_identity.current.account_id}-${var.lambda_function_name}"
  alarm_description   = "Throttles High for ${var.throttles_critical_threshold}  over ${var.throttles_critical_period} secs"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.throttles_critical_evaluation_periods
  threshold           = var.throttles_critical_threshold
  period              = var.throttles_critical_period

  namespace   = "AWS/Lambda"
  metric_name = "Throttles"
  statistic   = "Sum"

  dimensions = {
    FunctionName  = aws_lambda_function.lambda_function_name.function_name
    Resource = aws_lambda_function.lambda_function_name.function_name
  }

  alarm_actions = var.throttles_critical_alarm_to_spectrum == true ? concat([
    "arn:aws:sns:${var.aws_region}:${local.spectrumEnv}:bki-spectrum-custom-alarm-metadata"
  ], var.throttles_critical_alarm_actions) : var.throttles_critical_alarm_actions
  
  ok_actions = var.throttles_critical_ok_to_spectrum == true ? concat([
    "arn:aws:sns:${var.aws_region}:${local.spectrumEnv}:bki-spectrum-custom-alarm-metadata"
  ], var.throttles_critical_ok_actions) : var.throttles_critical_ok_actions

  tags = {
      Name       = "bki-cw-throttlesAlarmCritical-${data.aws_caller_identity.current.account_id}-${var.lambda_function_name}"
      appid      = var.appid_tag
      env        = var.env_tag
      awsaccount = var.awsaccount_tag
      createdby  = var.createdby_tag
      function   = "Durations High for ${var.throttles_critical_threshold}  over ${var.throttles_critical_period} secs"
      Severity           = "Critical"
      Division           = var.division_tag
      ApplicationSegment = var.application_segment_tag
      Environment        = var.env_tag
      Notes              = var.notes_tag
    }
}

resource "aws_cloudwatch_metric_alarm" "throttles_warning" {
  count = var.throttles_warning_alarm_enabled == true ? 1 : 0 
  alarm_name = "bki-cw-throttlesAlarmWarning-${data.aws_caller_identity.current.account_id}-${var.lambda_function_name}"
  alarm_description   = "Throttles High for ${var.throttles_warning_threshold}  over ${var.throttles_warning_period} secs"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.throttles_warning_evaluation_periods
  threshold           = var.throttles_warning_threshold
  period              = var.throttles_warning_period

  namespace   = "AWS/Lambda"
  metric_name = "Throttles"
  statistic   = "Sum"

  dimensions = {
    FunctionName  = aws_lambda_function.lambda_function_name.function_name
    Resource = aws_lambda_function.lambda_function_name.function_name
  }

  alarm_actions = var.throttles_warning_alarm_to_spectrum == true ? concat([
    "arn:aws:sns:${var.aws_region}:${local.spectrumEnv}:bki-spectrum-custom-alarm-metadata"
  ], var.throttles_warning_alarm_actions) : var.throttles_warning_alarm_actions
  
  ok_actions = var.throttles_warning_ok_to_spectrum == true ? concat([
    "arn:aws:sns:${var.aws_region}:${local.spectrumEnv}:bki-spectrum-custom-alarm-metadata"
  ], var.throttles_warning_ok_actions) : var.throttles_warning_ok_actions

  tags = {
      Name       = "bki-cw-throttlesAlarmWarning-${data.aws_caller_identity.current.account_id}-${var.lambda_function_name}"
      appid      = var.appid_tag
      env        = var.env_tag
      awsaccount = var.awsaccount_tag
      createdby  = var.createdby_tag
      function   = "Throttles High for ${var.throttles_warning_threshold}  over ${var.throttles_warning_period} secs"
      Severity           = "Minor"
      Division           = var.division_tag
      ApplicationSegment = var.application_segment_tag
      Environment        = var.env_tag
      Notes              = var.notes_tag
    }
}
