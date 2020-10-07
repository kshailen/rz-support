variable "role_name" {
  description = "The name of the role to create"
  type        = string
}

variable "role_description" {
  description = "The description of the role"
  type        = string
}

variable "assume_role_policy_file" {
  description = "Name of the JSON file containing the policy for assume role"
  type        = string
  default     = null
}

variable "assume_role_policy_inline" {
  description = "Inline JSON containing the policy for assume role"
  type        = string
  default     = null
}

variable "attach_policies" {
  description = "List of policie arns to attach to this role"
  type        = list
  default     = []
}

variable "appid_tag" {
  description = "The primary AppID that will use this resourece."
  type        = string
}

variable "env_tag" {
  description = "Environment(s) that this role will be referenced."
  type        = string
}

variable "awsaccount_tag" {
  description = "Account Name"
  type        = string
}

variable "function_tag" {
  description = "Function or purpose of the role."
  type        = string
}

variable "createdby_tag" {
  description = "e-number@lpsvcs.com"
  type        = string
}

variable "extended_tags" {
  type        = map(string)
  default     = {}
  description = "Key value map for additional user supplied tags"
}

variable "conditional_create" {
  description = "If set to 0, do not create this resource"
  type        = string
  default     = 1
}

variable "force_detach_policies" {
  description = "Force Detach Policies"
  type = bool
  default = true
}
