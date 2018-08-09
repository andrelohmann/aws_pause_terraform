# tf\_aws\_pause
## a Lambda-powered EC2 Instances pause Terraform Module

A Terraform module for creating a Lambda Function that automatically stops expensive non-ephemeral instances during night-time (e.g.).
The function is triggered via a CloudWatch event that can be freely configured by a cronlike expression.

If you are running Development Instances on your AWS Stack, that don't need to be running all the time, you can set the Tags of your pausable instances as follows:

```
Ephemeral=False
Pausable=True
```

There also exists a go-lang cli tool, that allows to start/stop these instances on demand:

https://github.com/andrelohmann/awspause

## Input Variables:
- `unique_name`      - Just a marker for the Terraform stack. Default is "v1"`
- `stack_prefix`     - Prefix for resource generation. Default is `aws_pause`
- `cron_expression`  - Cron expression for CloudWatch events. Default is `"22 1 * * ? *"`
- `regions`          - List of regions in which the Lambda function should run. Requires at least one entry (eg. `["eu-west-1", "us-west-1"]`)

## Outputs
Default outputs are `aws_iam_role_arn` with the value of the created IAM role for the Lambda function and the `lambda_function_name`

## Example usage
In your Terrafom `main.tf` call the module with the required variables.

```
module "aws_pause" {
  source = "github.com/andrelohmann/aws_pause_terraform"
  unique_name      = "v2"
  stack_prefix     = "aws_pause"
  cron_expression  = "0 22 * * ? *"
  regions          = ["eu-west-1", "eu-central-1"]
}
```
