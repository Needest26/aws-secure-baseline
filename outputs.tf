# Outputs: the handful of facts worth printing after `terraform apply`,
# so you can find what was built without clicking through the console.

output "vpc_id" {
  description = "ID of the VPC."
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets, one per Availability Zone."
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets, one per Availability Zone."
  value       = aws_subnet.private[*].id
}

output "web_security_group_id" {
  description = "Security group for the internet-facing tier."
  value       = aws_security_group.web.id
}

output "app_security_group_id" {
  description = "Security group for the private app tier."
  value       = aws_security_group.app.id
}

output "log_bucket_name" {
  description = "S3 bucket that stores the CloudTrail logs."
  value       = aws_s3_bucket.logs.id
}

output "cloudtrail_name" {
  description = "Name of the CloudTrail trail."
  value       = aws_cloudtrail.main.name
}

output "cloudtrail_log_group" {
  description = "CloudWatch Logs group that receives CloudTrail events."
  value       = aws_cloudwatch_log_group.cloudtrail.name
}

output "cloudtrail_role_name" {
  description = "IAM role CloudTrail assumes to write to CloudWatch Logs."
  value       = aws_iam_role.cloudtrail_to_cloudwatch.name
}

output "root_usage_alarm_name" {
  description = "CloudWatch alarm that fires when the root user is used."
  value       = aws_cloudwatch_metric_alarm.root_usage.alarm_name
}
