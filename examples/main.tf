module "egress_vpc" {
  source                  = "../"
  cidr                    = "10.1.1.0/24" # cidr shouldn't be bigger than /24
  home_net                = "10.0.0.0/8"
  public_subnets          = ["10.1.1.64/27", "10.1.1.96/27", "10.1.1.128/27", "10.1.1.160/27"]
  firewall_subnets        = ["10.1.1.0/28", "10.1.1.16/28", "10.1.1.32/28", "10.1.1.48/28"]
  transit_gateway_subnets = ["10.1.1.192/28", "10.1.1.208/28", "10.1.1.224/28", "10.1.1.240/28"]
  availability_zone_names = ["us-east-1a", "us-east-1b", "us-east-1c", "us-east-1d"]
}
output "availability_zone_names" {
  value = module.egress_vpc.availability_zone_names
}
