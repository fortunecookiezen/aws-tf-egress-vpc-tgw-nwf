data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_availability_zones" "azs" {
  state = "available"
}
data "aws_ec2_transit_gateway" "this" {
  id = var.transit_gateway_id
}
