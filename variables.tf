# Inputs. Anything that might differ between deployments lives here
# instead of being hard-coded in the resources. Each variable has a safe
# default, so `terraform apply` works with no extra input.

variable "aws_region" {
  description = "AWS region to build in."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Short name used as a prefix on every resource and as the Project tag."
  type        = string
  default     = "secure-baseline"
}

# --- Network ---

variable "vpc_cidr" {
  description = "Address range for the whole VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "Address ranges for the public subnets, one per Availability Zone."
  type        = list(string)
  default     = ["10.0.0.0/24", "10.0.1.0/24"]
}

variable "private_subnet_cidrs" {
  description = "Address ranges for the private subnets, one per Availability Zone."
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
}

variable "app_port" {
  description = "Port the app tier listens on. Only the web tier may reach it."
  type        = number
  default     = 8080
}

# --- Logging ---

variable "log_retention_days" {
  description = "How long CloudWatch Logs keeps CloudTrail events. The S3 bucket keeps the full history."
  type        = number
  default     = 30
}

variable "force_destroy_log_bucket" {
  description = "Allow terraform destroy to delete the log bucket even when it contains logs. Set to false outside a demo."
  type        = bool
  default     = true
}

# --- Monitoring ---

variable "alert_email" {
  description = "Email address to notify when the root-usage alarm fires. Leave empty for no email."
  type        = string
  default     = ""
}
