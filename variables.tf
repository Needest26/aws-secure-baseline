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
