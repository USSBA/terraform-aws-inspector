data "archive_file" "lambda_archive" {
  type        = "zip"
  source_file = "${path.module}/${var.lambda_file_name}.py"
  output_path = "${var.lambda_file_name}.zip"
}

resource "aws_lambda_function" "lambda_function" {
  environment {
    variables = merge(var.lambda_env_variables, { DELIVERY_SNS_TOPIC = aws_sns_topic.delivery_sns_topic.name })
  }
  depends_on       = [aws_sns_topic.delivery_sns_topic]
  filename         = data.archive_file.lambda_archive.output_path
  function_name    = "${var.name_prefix}-inspector-${var.lambda_file_name}"
  handler          = "${var.lambda_file_name}.lambda_handler"
  memory_size      = var.lambda_memory_size
  publish          = true
  role             = aws_iam_role.lambda_role.arn
  runtime          = var.lambda_runtime
  source_code_hash = data.archive_file.lambda_archive.output_base64sha256
  timeout          = var.lambda_timeout
}

data "aws_iam_policy_document" "lambda_assume_role_policy" {
  statement {
    sid     = "AssumeRole"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_role" {
  name               = "${var.name_prefix}-inspector-lambda-finding-processor"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role_policy.json
  path               = "/service-role/"
}

data "aws_iam_policy_document" "lambda_main_policy" {
  policy_id = "${var.name_prefix}Inspectorlambda-finding-processor"

  statement {
    sid = "LogAcess"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["*"]
  }
  statement {
    sid = "SNSAccess"
    actions = [
      "SNS:CreateTopic",
      "SNS:Subscribe",
      "SNS:ListSubscriptionsByTopic",
      "SNS:Publish"
    ]
    resources = [aws_sns_topic.sns_topic.arn, aws_sns_topic.delivery_sns_topic.arn]
  }
  statement {
    sid       = "InspectorFindingsAccess"
    actions   = ["inspector:DescribeFindings"]
    resources = ["*"]
  }
  depends_on = [aws_sns_topic.delivery_sns_topic, aws_sns_topic.sns_topic]
}

resource "aws_iam_policy" "lambda_basic_execution_policy" {
  name   = "${title(var.name_prefix)}InspectorLambda"
  policy = data.aws_iam_policy_document.lambda_main_policy.json
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution_policy_attachment" {
  policy_arn = aws_iam_policy.lambda_basic_execution_policy.arn
  role       = aws_iam_role.lambda_role.name
}

resource "aws_sns_topic" "delivery_sns_topic" {
  name   = "${var.name_prefix}-inspector-finding-delivery"
  policy = data.aws_iam_policy_document.sns_topic_delivery_policy.json
}

data "aws_iam_policy_document" "sns_topic_delivery_policy" {
  policy_id = "${var.name_prefix}-inspector-sns-delivery-policy"
  statement {
    actions = ["SNS:Publish"]

    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    resources = ["arn:aws:lambda:${data.aws_region.current_region.name}:${data.aws_caller_identity.current_identity.account_id}:function:${var.name_prefix}-${var.lambda_file_name}"]
  }
}

resource "null_resource" "sns_subscribe" {
  depends_on = [aws_sns_topic.delivery_sns_topic]
  triggers = {
    sns_topic_arn = aws_sns_topic.delivery_sns_topic.arn
  }
  count = length(var.report_email_target)

  provisioner "local-exec" {
    command = "aws sns subscribe --region ${data.aws_region.current_region.name} --topic-arn ${aws_sns_topic.delivery_sns_topic.arn} --protocol email --notification-endpoint ${element(var.report_email_target, count.index)}"
  }
}