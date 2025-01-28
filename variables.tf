variable "name_prefix" {
  type        = string
  description = "name prefix"
}

variable "rules" {
  type        = any
  description = "rules"
  default     = []
}

variable "iterated_rules" {
  type        = any
  description = "iterated rules"
  default     = []
}

variable "create_group_name" {
  type        = bool
  description = "create group"
  default     = false
}

variable "group_name" {
  type        = string
  description = "group name"
  default     = "default"
}

variable "group_tags" {
  type        = map(string)
  description = "group tags"
  default     = {}
}

variable "create_default_role" {
  type        = bool
  description = "create default role"
  default     = false
}

variable "default_role_name" {
  type        = string
  description = "default role name"
  default     = ""
}

variable "default_role_policy_arns" {
  type        = list(string)
  description = "default role policy arns"
  default     = []
}

variable "default_role_policy" {
  type        = any
  description = "default role assume policy"
  default = {
    "Version" : "2008-10-17",
    "Statement" : [
      {
        "Sid" : "defaultRolePolicySchedulerAssumeRole",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "scheduler.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      },
      {
        "Sid" : "defaultRolePolicyStatesAssumeRole",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "states.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  }
}