# The IAM role: lets CloudTrail copy its events into CloudWatch Logs.
#
# A role is a set of permissions with no password and no keys. A
# trusted party "assumes" it and gets short-lived credentials. A role
# has two halves: who may assume it (the trust policy) and what it may
# do once assumed (the permissions policy).
#
# This one is least privilege: one service may assume it, and it can
# perform two actions on one log group.

# Trust policy: only the CloudTrail service may assume this role. No
# person and no other service can.
data "aws_iam_policy_document" "cloudtrail_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "cloudtrail_to_cloudwatch" {
  name               = "${var.project_name}-cloudtrail-to-cloudwatch"
  description        = "Lets CloudTrail deliver events to one CloudWatch Logs group"
  assume_role_policy = data.aws_iam_policy_document.cloudtrail_assume_role.json
}

# Permissions policy: create a log stream and write events to it.
# The resource is narrowed to CloudTrail's own log streams inside this
# project's log group. The role cannot read logs, delete anything or
# touch any other log group.
data "aws_iam_policy_document" "cloudtrail_to_cloudwatch" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = [
      "${aws_cloudwatch_log_group.cloudtrail.arn}:log-stream:${local.account_id}_CloudTrail_${var.aws_region}*",
    ]
  }
}

resource "aws_iam_role_policy" "cloudtrail_to_cloudwatch" {
  name   = "write-cloudtrail-events"
  role   = aws_iam_role.cloudtrail_to_cloudwatch.id
  policy = data.aws_iam_policy_document.cloudtrail_to_cloudwatch.json
}
