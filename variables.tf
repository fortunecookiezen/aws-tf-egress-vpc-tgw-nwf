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

variable "firewall_log_group_name" {
  description = "name of the cloudwatch log group for firewall logs. Defaults to \"Firewall\"."
  type        = string
  default     = "firewall"
}

variable "s3_logs" {
  description = "send firewall logs to s3 bucket. If unset, logs will not be sent. Allowed values are \"ALERT\" and \"FLOW\"."
  type        = string
  default     = ""
}

variable "vpc_flow_logs" {
  description = "Log vpc traffic flows. If unset, vpc traffic flows will not be logged. If set, all vpc traffic will be logged. Allowed values are \"CLOUDWATCH\" and \"S3\"."
  type        = string
  default     = ""
}

variable "flow_log_bucket_arn" {
  description = "Optional arn of s3 bucket destination for flow logs. If not specified, a bucket will be created."
  type        = string
  default     = ""
}

variable "home_net" {
  description = "summary cidr block for all resources behind this egress vpc"
  type        = string
  default     = "10.0.0.0/8"
}

variable "name" {
  description = "Name to be used on all the resources as identifier"
  type        = string
  default     = "anwf"
}

variable "firewall_policy_arn" {
  description = "arn of the firewall policy. Overrides default policy of any -> any"
  type        = string
  default     = ""
}

variable "kms_master_key_id" {
  description = "AWS KMS master key id used for bucket and log storage encryption. If empty, this module will use the default AWS-managed kms service key."
  type        = string
  default     = ""
}

variable "log_retention_days" {
  description = "Number of days to retain cloudwatch logs, default is 90"
  type        = number
  default     = 90
}

variable "s3_log_bucket" {
  description = "Name of s3 bucket for s3 bucket access logs"
  type        = string
  default     = ""
}

variable "transit_gateway_id" {
  description = "id of the transit gateway for tgw subnet attachment"
  type        = string
}
variable "http_ports" {
  description = "Destination ports for HTTP traffic"
  type        = list(string)
  default     = ["80"]
}

variable "tls_ports" {
  description = "Destination ports for TLS traffic"
  type        = list(string)
  default     = ["443"]
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
  default     = "network-firewall"
}

variable "transit_gateway_subnet_suffix" {
  description = "Suffix to append to transit gateway subnet name"
  type        = string
  default     = "transit-gateway"
}

# maps
variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "bucket_tags" {
  description = "A map of tags to add to s3 buckets"
  type        = map(string)
  default     = {}
}

variable "vpc_tags" {
  description = "Additional tags for the VPC"
  type        = map(string)
  default     = {}
}


variable "public_subnet_route_table_tags" {
  description = "Additional tags for the public subnet route tables"
  type        = map(string)
  default     = {}
}

variable "firewall_subnet_route_table_tags" {
  description = "Additional tags for the firewall subnet route tables"
  type        = map(string)
  default     = {}
}

variable "transit_gateway_subnet_route_table_tags" {
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
  description = "Additional tags for the firewall"
  type        = map(string)
  default     = {}
}

variable "firewall_policy_tags" {
  description = "Additional tags for the firewall policy"
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
