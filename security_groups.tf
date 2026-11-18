# Security groups: the firewalls.
#
# A security group is a firewall attached to a resource (a server, a
# load balancer, a database). It blocks everything inbound unless a
# rule allows it. Nothing is attached to these groups yet; they are the
# pattern any workload placed in this network would use.
#
# The pattern is two tiers. The internet may reach the web tier on
# HTTPS only, and only the web tier may reach the app tier. There is no
# SSH rule anywhere.

# Every VPC is born with a "default" security group that lets its
# members talk to each other freely. Resources land in it when nobody
# picks a group. Taking it over with no rules means that mistake results
# in no access instead of open access.
resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-default-locked"
  }
}

# --- Web tier: what faces the internet ---

resource "aws_security_group" "web" {
  name        = "${var.project_name}-web"
  description = "Internet-facing tier: HTTPS in from anywhere"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-web"
  }
}

# Inbound: HTTPS (port 443) from anywhere. Nothing else gets in.
resource "aws_vpc_security_group_ingress_rule" "web_https_in" {
  security_group_id = aws_security_group.web.id
  description       = "HTTPS from the internet"

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "tcp"
  from_port   = 443
  to_port     = 443
}

# Outbound: only to the app tier, only on the app port.
resource "aws_vpc_security_group_egress_rule" "web_to_app" {
  security_group_id = aws_security_group.web.id
  description       = "Forward requests to the app tier only"

  referenced_security_group_id = aws_security_group.app.id
  ip_protocol                  = "tcp"
  from_port                    = var.app_port
  to_port                      = var.app_port
}

# --- App tier: private, never reachable from the internet ---

resource "aws_security_group" "app" {
  name        = "${var.project_name}-app"
  description = "Private tier: accepts traffic only from the web tier"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-app"
  }
}

# Inbound: the source is the web security group itself, not an IP
# range. Whatever is in the web tier may connect; nothing else can,
# even from inside the VPC.
resource "aws_vpc_security_group_ingress_rule" "app_from_web" {
  security_group_id = aws_security_group.app.id
  description       = "App port from the web tier only"

  referenced_security_group_id = aws_security_group.web.id
  ip_protocol                  = "tcp"
  from_port                    = var.app_port
  to_port                      = var.app_port
}

# Outbound: HTTPS only, which is what calling AWS services needs.
resource "aws_vpc_security_group_egress_rule" "app_https_out" {
  security_group_id = aws_security_group.app.id
  description       = "HTTPS out, for calling AWS services"

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "tcp"
  from_port   = 443
  to_port     = 443
}
