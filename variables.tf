variable "enable_dns_hostnames" {
  description = "Should be true to enable DNS hostnames in the VPC"
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "Should be true to enable DNS support in the VPC"
  type        = bool
  default     = true
}

variable "availability_zone_names" {
  description = "list of availability zones for subnet coverage, like us-east-1a, us-east-1b, etc. This module will create a set of three subnets (public, firewall, transit gateway) per availability zone"
  type        = list(string)
  default     = ["us-east-1a"]
}

variable "cidr" {
  description = "cidr block for this vpc. It really doesn't need to be larger than /24."
  type        = string
}

variable "home_net" {
  description = "summary cidr block for all resources behind this egress vpc"
  type        = string
  default     = "10.0.0.0/8"
}

variable "name" {
  description = "Name to be used on all the resources as identifier"
  type        = string
  default     = "egress-vpc"
}
variable "public_subnets" {
  description = "A list of public subnet cidr blocks inside the VPC"
  type        = list(string)
  default     = []
}

variable "firewall_subnets" {
  description = "A list of firewall subnet cidr blocks inside the VPC"
  type        = list(string)
  default     = []
}

variable "transit_gateway_subnets" {
  description = "A list of transit gateway attached subnet cidr blocks inside the VPC"
  type        = list(string)
  default     = []
}

variable "private_route_table_routes" {
  description = "Configuration block of routes. See https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/default_route_table#route"
  type        = list(map(string))
  default     = []
}

variable "public_subnet_suffix" {
  description = "Suffix to append to public subnet name"
  type        = string
  default     = "public"
}

variable "firewall_subnet_suffix" {
  description = "Suffix to append to firewall subnet name"
  type        = string
  default     = "nwf"
}

variable "transit_gateway_subnet_suffix" {
  description = "Suffix to append to transit gateway subnet name"
  type        = string
  default     = "tgw"
}

# maps
variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "vpc_tags" {
  description = "Additional tags for the VPC"
  type        = map(string)
  default     = {}
}


variable "public_route_table_tags" {
  description = "Additional tags for the public subnet route tables"
  type        = map(string)
  default     = {}
}

variable "firewall_route_table_tags" {
  description = "Additional tags for the firewall subnet route tables"
  type        = map(string)
  default     = {}
}

variable "transit_gateway_route_table_tags" {
  description = "Additional tags for the transit gateway subnet route tables"
  type        = map(string)
  default     = {}
}

variable "public_subnet_tags" {
  description = "Additional tags for the public subnets"
  type        = map(string)
  default     = {}
}

variable "firewall_subnet_tags" {
  description = "Additional tags for the firewall subnets"
  type        = map(string)
  default     = {}
}

variable "firewall_tags" {
  description = "Additional tags for the firewall subnets"
  type        = map(string)
  default     = {}
}

variable "transit_gateway_subnet_tags" {
  description = "Additional tags for the transit gateway subnets"
  type        = map(string)
  default     = {}
}

variable "igw_tags" {
  description = "Additional tags for the internet gateway"
  type        = map(string)
  default     = {}
}

variable "public_acl_tags" {
  description = "Additional tags for the public subnets network ACL"
  type        = map(string)
  default     = {}
}

variable "firewall_acl_tags" {
  description = "Additional tags for the firewall subnets network ACL"
  type        = map(string)
  default     = {}
}

variable "transit_gateway_acl_tags" {
  description = "Additional tags for the transit gateway subnets network ACL"
  type        = map(string)
  default     = {}
}

variable "nat_gateway_tags" {
  description = "Additional tags for the NAT gateways"
  type        = map(string)
  default     = {}
}

variable "nat_eip_tags" {
  description = "Additional tags for the NAT EIP"
  type        = map(string)
  default     = {}
}
