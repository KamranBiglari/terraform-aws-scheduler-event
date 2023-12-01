output "default_iam_role" {
  value = try(aws_iam_role.default[0].arn,null)
}

output "inline_iam_role" {
  value = {for k,v in aws_iam_role.this : k => v.arn}
}

output "schedule_group" {
  value =  try(aws_scheduler_schedule_group.this[0].name,null)
}

output "schedule" {
  value = {for k,v in aws_scheduler_schedule.this : k => 
  {
    arn = v.arn
    name = v.id
    state = v.state
    group_name = v.group_name
    schedule_expression = v.schedule_expression
    schedule_expression_timezone = v.schedule_expression_timezone
    flexible_time_window = v.flexible_time_window
    target = v.target
  }}
}