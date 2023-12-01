module "scheduler_ecs_control" {
  source      = "../../"
  name_prefix = "scheduler-ecs-servicecontrol-"

  create_group_name  = true
  group_name  = "scheduler-ecs-servicecontrol"

  create_default_role = true
  default_role_name   = "iam-role"
  default_role_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonECS_FullAccess",
  ]

  rules = [
    {
      name       = "start-at-17-01-every-sunday"
      description = "start at 17:00 every sunday on America/New_York"
      timezone   = "America/New_York"
      expression = "cron(1 17 ? * SUN *)"
      target = {
        arn = "arn:aws:scheduler:::aws-sdk:ecs:updateService"
        input = {
          Cluster      = "MyCluster"
          Service      = "ServiceName"
          DesiredCount = 1
        }
      }
    },
    {
      name       = "stop-at-17-01-every-friday"
      description = "stop at 17:00 every friday on America/New_York"
      timezone   = "America/New_York"
      expression = "cron(1 17 ? * FRI *)"
      target = {
        arn = "arn:aws:scheduler:::aws-sdk:ecs:updateService"
        input = {
          Cluster      = "MyCluster"
          Service      = "ServiceName"
          DesiredCount = 0
        }
      }
    }
  ]

}
