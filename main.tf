terraform {
  required_version = "~> 0.12.9"
  required_providers {
    aws = "~> 2.30"
  }
}
locals {
  enabled_count   = var.enabled ? 1 : 0
  scheduled_count = var.enable_scheduled_event && var.enabled ? 1 : 0
  assessment_ruleset = compact([
    var.ruleset_cve ? "arn:aws:inspector:us-east-1:316112463485:rulespackage/0-gEjTy7T7" : "",
    var.ruleset_cis ? "arn:aws:inspector:us-east-1:316112463485:rulespackage/0-rExsr2X8" : "",
    var.ruleset_security_best_practices ? "arn:aws:inspector:us-east-1:316112463485:rulespackage/0-R01qwB5Q" : "",
    var.ruleset_network_reachability ? "arn:aws:inspector:us-east-1:316112463485:rulespackage/0-PmNV0Tcd" : "",
    ]
  )
}

data "aws_iam_policy_document" "inspector_event_role_policy" {
  count = local.scheduled_count
  statement {
    sid = "StartAssessment"
    actions = [
      "inspector:StartAssessmentRun",
    ]
    resources = [
      "*"
    ]
  }
}

resource "aws_inspector_assessment_target" "assessment" {
  count = local.enabled_count
  name  = "${var.name_prefix}-assessment-target"
}

resource "aws_inspector_assessment_template" "assessment" {
  count              = local.enabled_count
  name               = "${var.name_prefix}-assessment-template"
  target_arn         = "${aws_inspector_assessment_target.assessment[0].arn}"
  duration           = var.assessment_duration
  rules_package_arns = local.assessment_ruleset
}

resource "aws_iam_role" "inspector_event_role" {
  count = local.scheduled_count
  name  = "${var.name_prefix}-inspector-event-role"

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