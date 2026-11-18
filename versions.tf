# Which Terraform and which plugins this project needs.
#
# Terraform itself knows nothing about AWS. It downloads a "provider"
# (a plugin) that translates this code into AWS API calls. Pinning the
# versions means the project behaves the same next month, or on someone
# else's laptop, as it does today.

terraform {
  # Any Terraform from 1.10 upward.
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source = "hashicorp/aws"
      # "~> 6.0" means any 6.x release, but never 7.0, which could
      # contain breaking changes.
      version = "~> 6.0"
    }
  }
}
