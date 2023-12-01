module "scheduler_ecs_control" {
    source  = "../../"
    name_prefix    = "ecs-servicecontrol"
    group_name = "default"

    create_default_role = true
    default_role_name = "-servicecontrol-iam-role"
    default_role_policy_arns = [
        "arn:aws:iam::aws:policy/CloudWatchFullAccess",
        "arn:aws:iam::aws:policy/AWSStepFunctionsFullAccess",
    ]

    rules   = [
        {
            name = "run-on-2030-01-01-01-00"
            timezone = "America/New_York"
            expression = "2030-01-01T01:00:00Z"
            flexible_time_window = {
                mode = "OFF"
            } 
            target = {
                arn = "arn:aws:scheduler:::aws-sdk:ecs:updateService"
                role_arn = "arn:aws:iam::123456789012:role/ecs-service-role"
                input = {
                    Service = "MyData"
                    Cluster = "MyCluster"
                }
                retry_policy = {
                    maximum_retry_attempts = 1
                    maximum_event_age_in_minutes = 60
                }
            }
        },
        {
            name = "start_at_17_00_every_sunday"
            expression = "cron(1 17 ? * SUN *)"
            timezone = "Asia/Tokyo"
            flexible_time_window = {
                maximum_window_in_minutes = 1
                mode = "FLEXIBLE"
            }
            target = {
                arn = "arn:aws:scheduler:::aws-sdk:ecs:updateService"
                role = {
                    name = "ecs-service-role"
                    assume_role_policy = {
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
                    }
                    managed_policy_arns = [
                        "arn:aws:iam::aws:policy/CloudWatchFullAccess",
                        "arn:aws:iam::aws:policy/AWSStepFunctionsFullAccess",
                    ]
                }
                input = {
                    Service = "MyData"
                    Cluster = "MyCluster"
                }
            }
            state = "DISABLED" # Optional. Default: ENABLED
        },
        {
            name = "new_deployment_every_5_minutes"
            type = "rate"
            action = "new_deployment"
            expression = "rate(5 minutes)"
            target = {
                arn = "arn:aws:scheduler:::aws-sdk:ecs:updateService"
                input = {
                    Service = "MyData"
                    Cluster = "MyCluster"
                }
            }
        }
    ]

}