# Create an AWS IAM default role for the scheduler to assume. This role will be used to execute the target action.
resource "aws_iam_role" "default" {
  count               = (var.create_default_role) ? 1 : 0
  name                = "${var.name_prefix}${var.default_role_name}"
  assume_role_policy  = jsonencode(var.default_role_policy)
  managed_policy_arns = var.default_role_policy_arns
  tags = {
    Name = "${var.name_prefix}${var.default_role_name}"
  }
}

# Create an AWS IAM role for the scheduler to assume. This role will be used to execute the target action.
resource "aws_iam_role" "this" {
  for_each            = { for k, v in var.rules : k => v if can(v.target.role) }
  name                = "${var.name_prefix}${each.value.target.role.name}"
  assume_role_policy  = try(jsonencode(each.value.target.role.assume_role_policy), jsonencode(var.default_role_policy))
  managed_policy_arns = try(each.value.target.role.managed_policy_arns, var.default_role_policy_arns)
  tags = {
    Name = "${var.name_prefix}${each.value.target.role.name}"
  }
}

# Create schedule group
resource "aws_scheduler_schedule_group" "this" {
  count = (var.create_group_name) ? 1 : 0
  name  = try(var.group_name, null)
  tags  = try(var.group_tags, null)
}

resource "aws_scheduler_schedule" "this" {
  for_each    = { for k, v in var.rules : k => v }
  name        = "${var.name_prefix}${each.value.name}"
  description = try(each.value.description, null)
  group_name  = (var.create_group_name) ? aws_scheduler_schedule_group.this[0].name : var.group_name
  state       = try(each.value.state, "ENABLED")

  schedule_expression          = each.value.expression
  schedule_expression_timezone = try(each.value.timezone, "UTC")

  flexible_time_window {
    mode                      = try(each.value.flexible_time_window.mode, "OFF")
    maximum_window_in_minutes = try(each.value.flexible_time_window.maximum_window_in_minutes, null)
  }

  target {
    arn = each.value.target.arn
    role_arn = try(each.value.target.role_arn,
      try(aws_iam_role.this[each.key].arn, aws_iam_role.default[0].arn)
    )
    input = try(jsonencode(each.value.target.input), null)
    retry_policy {
      maximum_event_age_in_seconds = try(each.value.target.retry_policy.maximum_event_age_in_seconds, 60)
      maximum_retry_attempts       = try(each.value.target.retry_policy.maximum_retry_attempts, 1)
    }
  }

  depends_on = [
    aws_scheduler_schedule_group.this,
    aws_iam_role.default,
    aws_iam_role.this
  ]
}

resource "aws_iam_role" "default_iterated" {
  count = length(var.iterated_rules) > 0 ? 1 : 0
  name  = "${var.name_prefix}-default-iterated-role"
  assume_role_policy = jsonencode({
    "Version" : "2008-10-17",
    "Statement" : [
      {
        "Sid" : "",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "scheduler.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })
  managed_policy_arns = ["arn:aws:iam::aws:policy/AWSStepFunctionsFullAccess"]
  tags = {
    Name = "${var.name_prefix}-default-iterated-role"
  }
}

resource "aws_scheduler_schedule" "this_iterated" {
  for_each    = { for k, v in var.iterated_rules : k => v }
  name        = substr("${var.name_prefix}${each.value.name}",0,64)
  description = try(each.value.description, null)
  group_name  = (var.create_group_name) ? aws_scheduler_schedule_group.this[0].name : var.group_name
  state       = try(each.value.state, "ENABLED")

  schedule_expression          = each.value.expression
  schedule_expression_timezone = try(each.value.timezone, "UTC")

  flexible_time_window {
    mode                      = try(each.value.flexible_time_window.mode, "OFF")
    maximum_window_in_minutes = try(each.value.flexible_time_window.maximum_window_in_minutes, null)
  }

  target {
    arn      = aws_sfn_state_machine.this_iterated[each.key].arn
    role_arn = aws_iam_role.default_iterated[0].arn
    input = jsonencode(each.value.target.input)
    retry_policy {
      maximum_event_age_in_seconds = try(each.value.target.retry_policy.maximum_event_age_in_seconds, 60)
      maximum_retry_attempts       = try(each.value.target.retry_policy.maximum_retry_attempts, 1)
    }
  }

  depends_on = [
    aws_scheduler_schedule_group.this,
    aws_iam_role.default_iterated,
    aws_sfn_state_machine.this_iterated
  ]
}

resource "aws_iam_role" "iterated_rules" {
  for_each = { for k, v in var.iterated_rules : k => v if can(v.target.role) }
  name     = "${var.name_prefix}${each.value.target.role.name}"
  assume_role_policy = jsonencode({
    "Version" : "2008-10-17",
    "Statement" : [
      {
        "Sid" : "",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "scheduler.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })
  managed_policy_arns = try(each.value.target.role.managed_policy_arns, var.default_role_policy_arns)
  tags = {
    Name = "${var.name_prefix}${each.value.target.role.name}"
  }
}

resource "aws_sfn_state_machine" "this_iterated" {
  for_each = { for k, v in var.iterated_rules : k => v }
  name     = "${var.name_prefix}${each.value.name}"
  role_arn = try(each.value.target.role_arn,
    try(aws_iam_role.iterated_rules[each.key].arn, aws_iam_role.default[0].arn)
  )
  type = "EXPRESS"

  definition = templatefile("${path.module}/iterated_rules.tpl.json", {
    comment      = try(each.value.comment, ""),
    resourceName = tolist(split(":", each.value.target.arn))[length(tolist(split(":", each.value.target.arn))) - 1],
    resource     = each.value.target.arn,
    parameters   = jsonencode({ for k in tolist(keys(each.value.target.input[0])) : "${k}.$" => "$$.Map.Item.Value.${k}" }),
  })
}
