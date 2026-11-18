# The network: one VPC split into public and private subnets across two
# Availability Zones.
#
# Everything in this file is free. There is no NAT gateway on purpose:
# it has an hourly charge, and leaving it out means the private subnets
# have no path to the internet at all.

# Ask AWS which Availability Zones (separate data centres) this account
# can use in the region, instead of hard-coding names like "us-east-1a".
data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  # Use the first two. Two zones means one data centre can fail and the
  # other still has both a public and a private subnet.
  azs = slice(data.aws_availability_zones.available.names, 0, 2)
}

# The VPC is the private network itself: an isolated address range
# (10.0.0.0/16 = 65,536 addresses) that nothing can reach by default.
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# The internet gateway is the VPC's door to the internet. On its own it
# does nothing; a subnet only uses it if its route table points at it.
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# Public subnets: one per zone. This is where internet-facing things
# such as load balancers would go.
resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidrs)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnet_cidrs[count.index]
  availability_zone = local.azs[count.index]

  # Do not hand out public IP addresses automatically. A resource only
  # becomes reachable from the internet when someone decides it should.
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.project_name}-public-${local.azs[count.index]}"
    Tier = "public"
  }
}

# Private subnets: one per zone. This is where application servers and
# databases would go, out of reach of the internet.
resource "aws_subnet" "private" {
  count = length(var.private_subnet_cidrs)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = local.azs[count.index]

  tags = {
    Name = "${var.project_name}-private-${local.azs[count.index]}"
    Tier = "private"
  }
}

# A route table is the subnet's set of directions. This one says: send
# anything that is not local (0.0.0.0/0) to the internet gateway.
# That single route is what makes a subnet "public".
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

# The private route table has no internet route. It only knows the
# built-in local route, so traffic can move inside the VPC and nowhere
# else. That missing route is what makes a subnet "private".
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-private-rt"
  }
}

# Associations attach each subnet to its route table. Without them a
# subnet silently falls back to the VPC's default route table.
resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count = length(aws_subnet.private)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}
