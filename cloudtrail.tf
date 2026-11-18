# CloudTrail: the audit log of the account.
#
# CloudTrail records every API call: who did what, when, and from
# where. This trail sends each event to two places. The S3 bucket is
# the long-term record. CloudWatch Logs is the searchable copy that the
# alarm watches.

# The log group that receives the searchable copy of the events.
resource "aws_cloudwatch_log_group" "cloudtrail" {
  name = "/aws/cloudtrail/${var.project_name}"

  # Delete entries after this many days so storage does not grow
  # forever. The S3 bucket keeps the full history.
  retention_in_days = var.log_retention_days
}

resource "aws_cloudtrail" "main" {
  name           = local.trail_name
  s3_bucket_name = aws_s3_bucket.logs.id

  # Record activity in every region, not just this one. An attacker
  # using a region you never look at is still logged.
  is_multi_region_trail = true

  # Include global services such as IAM and sign-in events.
  include_global_service_events = true

  # CloudTrail writes signed digest files so you can prove later that
  # no log file was changed or deleted.
  enable_log_file_validation = true

  # Also deliver events to CloudWatch Logs, using the role in iam.tf.
  cloud_watch_logs_group_arn = "${aws_cloudwatch_log_group.cloudtrail.arn}:*"
  cloud_watch_logs_role_arn  = aws_iam_role.cloudtrail_to_cloudwatch.arn

  # The trail can only be created once the bucket accepts its writes
  # and the role has its permissions.
  depends_on = [
    aws_s3_bucket_policy.logs,
    aws_iam_role_policy.cloudtrail_to_cloudwatch,
  ]
}
