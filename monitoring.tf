# The alarm: tell someone when the root user is used.
#
# The root user can do anything in the account and cannot be restricted,
# so it should almost never be used. Any root activity is worth knowing
# about. Three pieces work together:
#
#   1. A metric filter reads the CloudTrail log group and counts events
#      made by root.
#   2. An alarm watches that count and fires when it is 1 or more.
#   3. An SNS topic receives the alarm and can pass it on by email.

# SNS topic: the mailbox alarms are posted to.
resource "aws_sns_topic" "security_alerts" {
  name = "${var.project_name}-security-alerts"
}

# Optional: email the alerts to someone. Only created when alert_email
# is set. AWS sends a confirmation email that must be clicked first.
resource "aws_sns_topic_subscription" "email" {
  count = var.alert_email == "" ? 0 : 1

  topic_arn = aws_sns_topic.security_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# Metric filter: turns matching log entries into a number. The pattern
# matches events made by the root user, leaving out actions AWS services
# perform on the account's behalf.
resource "aws_cloudwatch_log_metric_filter" "root_usage" {
  name           = "${var.project_name}-root-account-usage"
  log_group_name = aws_cloudwatch_log_group.cloudtrail.name
  pattern        = "{ $.userIdentity.type = \"Root\" && $.userIdentity.invokedBy NOT EXISTS && $.eventType != \"AwsServiceEvent\" }"

  metric_transformation {
    name      = "RootAccountUsage"
    namespace = "SecureBaseline"
    value     = "1"
  }
}

# Alarm: fires when root did anything at all in a 5-minute window.
resource "aws_cloudwatch_metric_alarm" "root_usage" {
  alarm_name        = "${var.project_name}-root-account-usage"
  alarm_description = "The root user was used in this account. Root should not be used for everyday work."

  namespace   = aws_cloudwatch_log_metric_filter.root_usage.metric_transformation[0].namespace
  metric_name = aws_cloudwatch_log_metric_filter.root_usage.metric_transformation[0].name

  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"

  # No root events means no data points. Treat that as healthy rather
  # than "insufficient data".
  treat_missing_data = "notBreaching"

  alarm_actions = [aws_sns_topic.security_alerts.arn]
}
