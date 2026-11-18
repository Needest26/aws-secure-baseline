# The log bucket: where CloudTrail stores the audit logs.
#
# In S3 each security setting is its own resource, so they are listed
# one by one below. Together they mean: private, encrypted, versioned,
# TLS only, and writable by this project's CloudTrail trail alone.

resource "aws_s3_bucket" "logs" {
  # Bucket names are unique across all of AWS, so the account number
  # and region are added to the end.
  bucket = "${var.project_name}-logs-${local.account_id}-${var.aws_region}"

  # Lets `terraform destroy` delete the bucket even though it holds log
  # files. Right for a demo you tear down; in production this would be
  # false so audit logs cannot be deleted by accident.
  force_destroy = var.force_destroy_log_bucket
}

# Block every form of public access. Even if someone later attaches a
# public policy or ACL by mistake, S3 refuses to honour it.
resource "aws_s3_bucket_public_access_block" "logs" {
  bucket = aws_s3_bucket.logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Encrypt every object at rest with S3-managed keys (SSE-S3, AES-256).
# No extra cost, and no key to manage.
resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Keep old versions of every object. If a log file is overwritten or
# deleted, the earlier copy is still there.
resource "aws_s3_bucket_versioning" "logs" {
  bucket = aws_s3_bucket.logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

# The bucket policy: who may do what with this bucket.
data "aws_iam_policy_document" "logs_bucket" {
  # Refuse any request that does not use TLS (HTTPS).
  statement {
    sid     = "DenyInsecureTransport"
    effect  = "Deny"
    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.logs.arn,
      "${aws_s3_bucket.logs.arn}/*",
    ]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }

  # CloudTrail checks the bucket's ownership before it writes.
  statement {
    sid       = "CloudTrailCheckBucketAcl"
    effect    = "Allow"
    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.logs.arn]

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    # Only this project's trail, not CloudTrail acting for anyone else.
    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = [local.trail_arn]
    }
  }

  # CloudTrail may write log files, only under this account's folder.
  statement {
    sid       = "CloudTrailWriteLogs"
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.logs.arn}/AWSLogs/${local.account_id}/*"]

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = [local.trail_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "logs" {
  bucket = aws_s3_bucket.logs.id
  policy = data.aws_iam_policy_document.logs_bucket.json

  # Apply the public access block first, so the two bucket-level changes
  # do not collide.
  depends_on = [aws_s3_bucket_public_access_block.logs]
}
