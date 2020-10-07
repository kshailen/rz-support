output "arn" {
  value       = aws_lambda_function.lambda_function_name.arn
  description = "ARN of the Lambda function"
}

output "lambda_function_name" {
  value       = aws_lambda_function.lambda_function_name.function_name
  description = "Lambda function name"
}

output "id" {
  value = aws_lambda_function.lambda_function_name.id
}

output "invoke_arn" {
  value = aws_lambda_function.lambda_function_name.invoke_arn
}

output "version" {
  value = aws_lambda_function.lambda_function_name.version
}

output "qualified_arn" {
  value = aws_lambda_function.lambda_function_name.qualified_arn
}
