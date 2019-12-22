terraform {
  required_version = "~> 0.12.9"
  required_providers {
    aws = "~> 2.30"
  }
}

data "aws_region" "current_region" {}
data aws_caller_identity "current_identity" {}

locals {
  enabled_count   = var.enabled ? 1 : 0
  scheduled_count = var.enable_scheduled_event && var.enabled ? 1 : 0
  ruleset_cis_arn = {
    "eu-west-1" = "arn:aws:inspector:eu-west-1:357557129151:rulespackage/0-sJBhCr0F"
    "us-east-1" = "arn:aws:inspector:us-east-1:316112463485:rulespackage/0-rExsr2X8"
  }
  ruleset_cve_arn = {
    "eu-west-1" = "arn:aws:inspector:eu-west-1:357557129151:rulespackage/0-ubA5XvBh"
    "us-east-1" = "arn:aws:inspector:us-east-1:316112463485:rulespackage/0-gEjTy7T7"
  }

  ruleset_network_reachability_arn = {
    "eu-west-1" = "arn:aws:inspector:eu-west-1:357557129151:rulespackage/0-SPzU33xe"
    "us-east-1" = "arn:aws:inspector:us-east-1:316112463485:rulespackage/0-PmNV0Tcd"
  }

  ruleset_security_best_practices_arn = {
    "eu-west-1" = "arn:aws:inspector:eu-west-1:357557129151:rulespackage/0-SnojL3Z6"
    "us-east-1" = "arn:aws:inspector:us-east-1:316112463485:rulespackage/0-R01qwB5Q"
  }

  assessment_ruleset = compact([
    var.ruleset_cis ? local.ruleset_cis_arn[data.aws_region.current_region.name] : "",
    var.ruleset_cve ? local.ruleset_cve_arn[data.aws_region.current_region.name] : "",
    var.ruleset_network_reachability ? local.ruleset_network_reachability_arn[data.aws_region.current_region.name] : "",
    var.ruleset_security_best_practices ? local.ruleset_security_best_practices_arn[data.aws_region.current_region.name] : "",
    ]
  )
}

data "aws_iam_policy_document" "inspector_event_role_policy" {
  count = local.scheduled_count
  statement {
    sid       = "StartAssessment"
    actions   = ["inspector:StartAssessmentRun"]
    resources = ["*"]
  }
}

resource "aws_inspector_assessment_target" "assessment" {
  count = local.enabled_count
  name  = "${var.name_prefix}-assessment-target"
}

resource "aws_inspector_assessment_template" "assessment" {
  count              = local.enabled_count
  name               = "${var.name_prefix}-assessment-template"
  target_arn         = var.enabled ? aws_inspector_assessment_target.assessment[0].arn : ""
  duration           = var.assessment_duration
  rules_package_arns = local.assessment_ruleset
}

resource "aws_iam_role" "inspector_event_role" {
  count = local.scheduled_count
  name  = "${var.name_prefix}-inspector-event"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "events.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "inspector_event" {
  count  = local.scheduled_count
  name   = "${var.name_prefix}-inspector-event-policy"
  role   = aws_iam_role.inspector_event_role[0].id
  policy = data.aws_iam_policy_document.inspector_event_role_policy[0].json
}

resource "aws_cloudwatch_event_rule" "inspector_event_schedule" {
  count               = local.scheduled_count
  name                = "${var.name_prefix}-inspector-schedule"
  description         = "Trigger an Inspector Assessment"
  schedule_expression = var.schedule_expression
}

resource "aws_cloudwatch_event_target" "inspector_event_target" {
  count    = local.scheduled_count
  rule     = aws_cloudwatch_event_rule.inspector_event_schedule[0].name
  arn      = aws_inspector_assessment_template.assessment[0].arn
  role_arn = aws_iam_role.inspector_event_role[0].arn
}

data "aws_iam_policy_document" "sns_topic_policy" {
  policy_id = "${var.name_prefix}-inspector-sns-publish-policy"
  statement {
    actions = ["SNS:Publish"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["inspector.amazonaws.com"]
    }
    resources = [
    "arn:aws:sns:${data.aws_region.current_region.name}:${data.aws_caller_identity.current_identity.account_id}:${var.name_prefix}-inspector"]

    sid = "${var.name_prefix}-inspector-sns-publish-statement"
  }

}

resource "aws_sns_topic" "sns_topic" {
  name                             = "${var.name_prefix}-inspector"
  policy                           = data.aws_iam_policy_document.sns_topic_policy.json
  lambda_failure_feedback_role_arn = "arn:aws:iam::${data.aws_caller_identity.current_identity.account_id}:role/SNSFailureFeedback"
  lambda_success_feedback_role_arn = "arn:aws:iam::${data.aws_caller_identity.current_identity.account_id}:role/SNSSuccessFeedback"
}

resource "aws_sns_topic_subscription" "lambda_findings_processor" {
  endpoint               = aws_lambda_function.lambda_function.arn
  protocol               = "lambda"
  topic_arn              = aws_sns_topic.sns_topic.arn
  endpoint_auto_confirms = true
  depends_on = [
  aws_lambda_function.lambda_function]
}

resource "aws_lambda_permission" "lambda_findings_processor_permission" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_function.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.sns_topic.arn
}

resource "null_resource" "inspector_sns" {
  provisioner "local-exec" {
    command = "aws --region ${data.aws_region.current_region.name} inspector subscribe-to-event --resource-arn ${aws_inspector_assessment_template.assessment[0].arn} --event FINDING_REPORTED --topic-arn ${aws_sns_topic.sns_topic.arn}"
  }
  depends_on = [aws_sns_topic.sns_topic]
}
