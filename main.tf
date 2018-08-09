# Create the lambda role (using lambdarole.json file)
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

resource "aws_iam_role" "aws_pause-role-lambdarole" {
  name               = "${var.stack_prefix}-role-lambdarole-${var.unique_name}"
  assume_role_policy = "${file("${path.module}/files/lambdarole.json")}"
}

# Apply the Policy Document we just created
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

resource "aws_iam_role_policy" "aws_pause-role-lambdapolicy" {
  name = "${var.stack_prefix}-role-lambdapolicy-${var.unique_name}"
  role = "${aws_iam_role.aws_pause-role-lambdarole.id}"
  policy = "${file("${path.module}/files/lambdapolicy.json")}"
}

# Output the ARN of the lambda role
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# Render vars.ini for Lambda function

data "template_file" "vars" {
    template = "${file("${path.module}/files/vars.ini.template")}"
    vars {
      REGIONS                            = "${join(",", var.regions)}"
    }
}


resource "null_resource" "buildlambdazip" {
  triggers { key = "${uuid()}" }
  provisioner "local-exec" {
    command = <<EOF
    mkdir -p ${path.module}/lambda && mkdir -p ${path.module}/tmp
    cp ${path.module}/ec2_pause/ec2_pause.py ${path.module}/tmp/ec2_pause.py
    echo "${data.template_file.vars.rendered}" > ${path.module}/tmp/vars.ini
EOF
  }
}
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/tmp"
  output_path = "${path.module}/lambda/${var.stack_prefix}-${var.unique_name}.zip"
  depends_on  = ["null_resource.buildlambdazip"]
}

# Create lambda function
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

resource "aws_lambda_function" "aws_pause_lambda" {
  function_name     = "${var.stack_prefix}_lambda_${var.unique_name}"
  filename          = "${path.module}/lambda/${var.stack_prefix}-${var.unique_name}.zip"
  source_code_hash  = "${data.archive_file.lambda_zip.output_base64sha256}"
  role              = "${aws_iam_role.aws_pause-role-lambdarole.arn}"
  runtime           = "python2.7"
  handler           = "aws_pause.lambda_handler"
  timeout           = "60"
  publish           = true
  depends_on        = ["null_resource.buildlambdazip"]
}

# Run the function with CloudWatch Event cronlike scheduler

resource "aws_cloudwatch_event_rule" "aws_pause_timer" {
  name = "${var.stack_prefix}_aws_pause_event_${var.unique_name}"
  description = "Cronlike scheduled Cloudwatch Event for stopping pausable EC2 instances"
  schedule_expression = "cron(${var.cron_expression})"
}

# Assign event to Lambda target
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

resource "aws_cloudwatch_event_target" "run_aws_pause_lambda" {
    rule = "${aws_cloudwatch_event_rule.aws_pause_timer.name}"
    target_id = "${aws_lambda_function.aws_pause_lambda.id}"
    arn = "${aws_lambda_function.aws_pause_lambda.arn}"
}

# Allow lambda to be called from cloudwatch
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

resource "aws_lambda_permission" "allow_cloudwatch_to_call" {
  statement_id = "${var.stack_prefix}_AllowExecutionFromCloudWatch_${var.unique_name}"
  action = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.aws_pause_lambda.function_name}"
  principal = "events.amazonaws.com"
  source_arn = "${aws_cloudwatch_event_rule.aws_pause_timer.arn}"
}
