output "aws_iam_role_arn" {
  value = "${aws_iam_role.aws_pause-role-lambdarole.arn}"
}


output "lambda_function_name" {
  value = "${aws_lambda_function.aws_pause_lambda.function_name}"
}
