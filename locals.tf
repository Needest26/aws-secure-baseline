# Shared lookups and names used by more than one file.

# Ask AWS which account these credentials belong to, so the account
# number never has to be written into the code.
data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id

  # The trail's name and ARN are worked out here, before the trail
  # exists, because the bucket policy has to name the trail and the
  # trail cannot be created until the bucket policy is in place.
  trail_name = "${var.project_name}-trail"
  trail_arn  = "arn:aws:cloudtrail:${var.aws_region}:${local.account_id}:trail/${local.trail_name}"
}
