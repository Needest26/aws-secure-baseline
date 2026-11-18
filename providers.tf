# How Terraform connects to AWS.
#
# There are no credentials in this file, on purpose. The provider picks
# them up from the signed-in AWS CLI session on the machine running it,
# so nothing secret is ever written into the code.

provider "aws" {
  region = var.aws_region

  # Every resource this project creates gets these tags automatically.
  # In the AWS console or a bill you can tell at a glance what created
  # a resource and which project it belongs to.
  default_tags {
    tags = {
      Project   = var.project_name
      ManagedBy = "Terraform"
    }
  }
}
