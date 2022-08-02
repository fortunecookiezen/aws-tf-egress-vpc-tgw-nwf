#
# Description: this file can be used to rapidly provision vpc endpoints
# for testing purposes. In this example, the file creates the endpoints
# necessary for ec2 intances to use Systems Manager in a private vpc
#

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

variable "vpc_id" {
  type    = string
  default = "vpc-01a6ca38851a2d182"
}

data "aws_vpc" "this" {
  id = var.vpc_id
}

# this will return all subnets in the vpc and attach the endpoints to them.
# this may not work if you have a mix of public and private subnets in your vpc
# but, if you do, why are you messing around with endpoints?
data "aws_subnets" "subnets" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
}

resource "aws_default_security_group" "default" {
  vpc_id = var.vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = [data.aws_vpc.this.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_vpc_endpoint" "this" {
  for_each = toset([
    "ec2",
    "ec2messages",
    "ssm",
    "ssmmessages"
  ])
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.${each.key}"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = toset(data.aws_subnets.subnets.ids)
  security_group_ids  = [aws_default_security_group.default.id]
  private_dns_enabled = true

  tags = {
    Name = "${var.vpc_id}-${each.key}"
  }
}

output "subnets" {
  value = data.aws_subnets.subnets.ids
}
