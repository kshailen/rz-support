data "aws_caller_identity" "current" {}

locals {
  role_name          = substr(var.role_name, 0, 7) == "BKI-SR-" ? var.role_name : "BKI-SR-${var.role_name}"
  role_file_contents = var.assume_role_policy_file != null ? file("${var.assume_role_policy_file}") : null
  role               = local.role_file_contents != null ? local.role_file_contents : var.assume_role_policy_inline
}

resource "aws_iam_role" "role" {
  count                 = var.conditional_create
  name                  = local.role_name
  description           = var.role_description
  permissions_boundary  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/BKI-PermissionBoundary"
  assume_role_policy    = local.role
  force_detach_policies = var.force_detach_policies

  tags = merge(
    {
      appid      = var.appid_tag
      env        = var.env_tag
      awsaccount = var.awsaccount_tag
      function   = var.function_tag
      createdby  = var.createdby_tag
  }, var.extended_tags)
}

resource "aws_iam_role_policy_attachment" "attachment" {
  count      = var.conditional_create == "0" ? 0 : length(var.attach_policies)
  policy_arn = var.attach_policies[count.index]
  role       = aws_iam_role.role[0].name
}
