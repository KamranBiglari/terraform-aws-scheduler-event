# terraform-aws-scheduler-event

[![GitHub release (latest by date)](https://img.shields.io/github/v/release/KamranBiglari/terraform-aws-scheduler-event)](https://github.com/KamranBiglari/terraform-aws-scheduler-event/releases/latest)


## How to use 

Rules need role to execute.
- default role: by setting the `create_default_role=true` default role will be created. You need to set `default_role_name` and `default_role_policy_arns` which is managed policies list.
- existing role: To use existing role you need to set the `role_arn` in `rules.target` block.
- create role: If you want to create a role you need to set `role` block in `rules.target` block. 

Scheduler group is used if you want to put scheduler events in group. By default it uses the `default` group. By setting `create_group_name=true` it will create a new group based on `group_name`. `group_name` should be unique. You can put events in existing groups by setting the `group_name`.

## Example

```
terraform {
  required_version = ">= 0.13.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region  = "eu-west-2"
}

module "scheduler_ecs_control" {
  source  = "KamranBiglari/scheduler-event/aws"
  name_prefix    = "ecs-servicecontrol"
  
  create_group_name  = true
  group_name  = "ecs-servicecontrol"

  create_default_role = true
  default_role_name   = "iam-role"
  default_role_policy_arns = [
    "arn:aws:iam::aws:policy/CloudWatchFullAccess",
    "arn:aws:iam::aws:policy/AmazonECS_FullAccess",
    "arn:aws:iam::aws:policy/AWSStepFunctionsFullAccess",
  ]

  rules = [
    {
      name       = "run-on-2030-01-01-01-00"
      timezone   = "America/New_York"
      expression = "2030-01-01T01:00:00Z"
      flexible_time_window = {
        mode = "OFF"
      }
      target = {
        arn      = "arn:aws:scheduler:::aws-sdk:ecs:updateService"
        role_arn = "arn:aws:iam::123456789012:role/ecs-service-role"
        input = {
          Cluster = "<MyCluster>"
          Service = "<ServiceName>"
        }
        retry_policy = {
          maximum_retry_attempts       = 1
          maximum_event_age_in_minutes = 60
        }
      }
    },
    {
      name       = "start_at_17_00_every_sunday"
      expression = "cron(1 17 ? * SUN *)"
      timezone   = "Asia/Tokyo"
      flexible_time_window = {
        maximum_window_in_minutes = 1
        mode                      = "FLEXIBLE"
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
            "arn:aws:iam::aws:policy/AmazonECS_FullAccess",
          ]
        }
        input = {
          Cluster = "<MyCluster>"
          Service = "<ServiceName>"
        }
      }
      state = "DISABLED" # Optional. Default: ENABLED
    },
    {
      name       = "new_deployment_every_5_minutes"
      type       = "rate"
      action     = "new_deployment"
      expression = "rate(5 minutes)"
      target = {
        arn = "arn:aws:scheduler:::aws-sdk:sfn:startExecution"
        input = {
          Input = {}
          StateMachineArn = "<STATE_MACHINE_ARN>"
        }
      }
    }
  ]

}


```
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.11 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_iam_role.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.default_iterated](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.iterated_rules](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_scheduler_schedule.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/scheduler_schedule) | resource |
| [aws_scheduler_schedule.this_iterated](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/scheduler_schedule) | resource |
| [aws_scheduler_schedule_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/scheduler_schedule_group) | resource |
| [aws_sfn_state_machine.this_iterated](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sfn_state_machine) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_create_default_role"></a> [create\_default\_role](#input\_create\_default\_role) | create default role | `bool` | `false` | no |
| <a name="input_create_group_name"></a> [create\_group\_name](#input\_create\_group\_name) | create group | `bool` | `false` | no |
| <a name="input_default_role_name"></a> [default\_role\_name](#input\_default\_role\_name) | default role name | `string` | `""` | no |
| <a name="input_default_role_policy"></a> [default\_role\_policy](#input\_default\_role\_policy) | default role assume policy | `any` | <pre>{<br/>  "Statement": [<br/>    {<br/>      "Action": "sts:AssumeRole",<br/>      "Effect": "Allow",<br/>      "Principal": {<br/>        "Service": "scheduler.amazonaws.com"<br/>      },<br/>      "Sid": ""<br/>    }<br/>  ],<br/>  "Version": "2008-10-17"<br/>}</pre> | no |
| <a name="input_default_role_policy_arns"></a> [default\_role\_policy\_arns](#input\_default\_role\_policy\_arns) | default role policy arns | `list(string)` | `[]` | no |
| <a name="input_group_name"></a> [group\_name](#input\_group\_name) | group name | `string` | `"default"` | no |
| <a name="input_group_tags"></a> [group\_tags](#input\_group\_tags) | group tags | `map(string)` | `{}` | no |
| <a name="input_iterated_rules"></a> [iterated\_rules](#input\_iterated\_rules) | iterated rules | `any` | `[]` | no |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | name prefix | `string` | n/a | yes |
| <a name="input_rules"></a> [rules](#input\_rules) | rules | `any` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_default_iam_role"></a> [default\_iam\_role](#output\_default\_iam\_role) | n/a |
| <a name="output_inline_iam_role"></a> [inline\_iam\_role](#output\_inline\_iam\_role) | n/a |
| <a name="output_schedule"></a> [schedule](#output\_schedule) | n/a |
| <a name="output_schedule_group"></a> [schedule\_group](#output\_schedule\_group) | n/a |
<!-- END_TF_DOCS -->