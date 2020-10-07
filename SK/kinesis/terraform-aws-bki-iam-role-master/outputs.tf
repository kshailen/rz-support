output "id" {
  value       = length(aws_iam_role.role) > 0 ? aws_iam_role.role[0].id : null
  description = "Role ID"
}

output "arn" {
  value       = length(aws_iam_role.role) > 0 ? aws_iam_role.role[0].arn : null
  description = "Role ARN"
}

output "name" {
  value       = length(aws_iam_role.role) > 0 ? aws_iam_role.role[0].name : null
  description = "Role Name"
}

output "assume_role_policy" {
  value       = length(aws_iam_role.role) > 0 ? aws_iam_role.role[0].assume_role_policy : null
  description = "The assume role policy assigned to the role"
}

output "permissions_boundary" {
  value       = length(aws_iam_role.role) > 0 ? aws_iam_role.role[0].permissions_boundary : null
  description = "The permissions_boundary assigned to the role"
}

output "unique_id" {
  value       = length(aws_iam_role.role) > 0 ? aws_iam_role.role[0].unique_id : null
  description = "The unique id of the role"
}

output "attachments" {
  value       = aws_iam_role_policy_attachment.attachment[*].policy_arn
  description = "Value suitable for use in a depends_on somewhere else"
}
