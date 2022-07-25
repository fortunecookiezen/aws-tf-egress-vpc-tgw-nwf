# AWS Central Egress VPC with Network Firewall

## Description

Terraform code to create a central egress vpc using nat gateway and aws network firewall as documented by aws in [Building a Scalable and Secure Multi-VPC AWS Network Infrastructure](https://docs.aws.amazon.com/whitepapers/latest/building-scalable-secure-multi-vpc-network-infrastructure/using-nat-gateway-with-firewall.html)

Credit to the following authors and projects for providing helpful examples:

- [aws-samples/aws-network-hub-for-terraform](https://github.com/aws-samples/aws-network-hub-for-terraform)
- [Mahattam Tomar](https://github.com/mattyait) and his project [terraform-aws-network-firewall](https://github.com/mattyait/terraform-aws-network-firewall).
- [Mukesh Sharma](https://github.com/msharma24) and his project [terraform-aws-network-firewall-deployment-models](https://github.com/msharma24/terraform-aws-network-firewall-deployment-models)

## Diagram

![Diagram](https://docs.aws.amazon.com/whitepapers/latest/building-scalable-secure-multi-vpc-network-infrastructure/images/centralized-egress-rt.png)

## Why did you build this?

Truthfully, I wanted a stack as simple to deploy as Checkpoint's CloudGuard [Transit Gateway Auto Scaling Group](https://github.com/CheckPointSW/CloudGuardIaaS/tree/master/aws/templates/tgw-asg), but utilizing aws services. I work with a firewall team that has little experience with aws and a strong preference for Checkpoint and this is a demonstration of how aws services can perform the same functionality.

<!-- BEGIN_TF_DOCS -->


## Usage
```hcl
module "egress_vpc" {
  source     = "../"
  cidr       = "10.1.1.0/24" # cidr shouldn't be bigger than /24
  home_net   = "10.0.0.0/8"
  http_ports = ["80"]
  tls_ports  = ["443"]

  # /24 can scale to 4 AZ
  #   public_subnets          = ["10.1.1.64/27", "10.1.1.96/27", "10.1.1.128/27", "10.1.1.160/27"]
  #   firewall_subnets        = ["10.1.1.0/28", "10.1.1.16/28", "10.1.1.32/28", "10.1.1.48/28"]
  #   transit_gateway_subnets = ["10.1.1.192/28", "10.1.1.208/28", "10.1.1.224/28", "10.1.1.240/28"]

  public_subnets          = ["10.1.1.64/27", "10.1.1.96/27"]
  firewall_subnets        = ["10.1.1.0/28", "10.1.1.16/28"]
  transit_gateway_subnets = ["10.1.1.192/28", "10.1.1.208/28"]
  availability_zone_names = ["us-east-1a", "us-east-1b"]
  transit_gateway_id      = "tgw-080381551298c8919"
  vpc_flow_logs           = "CLOUDWATCH"

  firewall_policy_tags = {
    Name = "default-egress-policy"
  }

  firewall_tags = {
    vpc = "egress-vpc"
  }
}
output "transit_gateway_subnets" {
  value = module.egress_vpc.transit_gateway_subnet_ids
}

output "firewall_endpoint_id" {
  value = module.egress_vpc.network_firewall_endpoint_id
}

output "anwf-eni-us-east-1a" {
  value = lookup(module.egress_vpc.eni_lookup, "us-east-1a")
}

output "anwf-eni-us-east-1b" {
  value = lookup(module.egress_vpc.eni_lookup, "us-east-1b")
}
```

## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

No modules.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_availability_zone_names"></a> [availability\_zone\_names](#input\_availability\_zone\_names) | list of availability zones for subnet coverage, like us-east-1a, us-east-1b, etc. This module will create a set of three subnets (public, firewall, transit gateway) per availability zone | `list(string)` | <pre>[<br>  "us-east-1a"<br>]</pre> | no |
| <a name="input_bucket_tags"></a> [bucket\_tags](#input\_bucket\_tags) | A map of tags to add to s3 buckets | `map(string)` | `{}` | no |
| <a name="input_cidr"></a> [cidr](#input\_cidr) | cidr block for this vpc. It really doesn't need to be larger than /24. | `string` | n/a | yes |
| <a name="input_enable_dns_hostnames"></a> [enable\_dns\_hostnames](#input\_enable\_dns\_hostnames) | Should be true to enable DNS hostnames in the VPC | `bool` | `true` | no |
| <a name="input_enable_dns_support"></a> [enable\_dns\_support](#input\_enable\_dns\_support) | Should be true to enable DNS support in the VPC | `bool` | `true` | no |
| <a name="input_firewall_acl_tags"></a> [firewall\_acl\_tags](#input\_firewall\_acl\_tags) | Additional tags for the firewall subnets network ACL | `map(string)` | `{}` | no |
| <a name="input_firewall_log_group_name"></a> [firewall\_log\_group\_name](#input\_firewall\_log\_group\_name) | name of the cloudwatch log group for firewall logs. Defaults to "Firewall". | `string` | `"firewall"` | no |
| <a name="input_firewall_policy_arn"></a> [firewall\_policy\_arn](#input\_firewall\_policy\_arn) | arn of the firewall policy. Overrides default policy of any -> any | `string` | `""` | no |
| <a name="input_firewall_policy_tags"></a> [firewall\_policy\_tags](#input\_firewall\_policy\_tags) | Additional tags for the firewall policy | `map(string)` | `{}` | no |
| <a name="input_firewall_subnet_route_table_tags"></a> [firewall\_subnet\_route\_table\_tags](#input\_firewall\_subnet\_route\_table\_tags) | Additional tags for the firewall subnet route tables | `map(string)` | `{}` | no |
| <a name="input_firewall_subnet_suffix"></a> [firewall\_subnet\_suffix](#input\_firewall\_subnet\_suffix) | Suffix to append to firewall subnet name | `string` | `"network-firewall"` | no |
| <a name="input_firewall_subnet_tags"></a> [firewall\_subnet\_tags](#input\_firewall\_subnet\_tags) | Additional tags for the firewall subnets | `map(string)` | `{}` | no |
| <a name="input_firewall_subnets"></a> [firewall\_subnets](#input\_firewall\_subnets) | A list of firewall subnet cidr blocks inside the VPC | `list(string)` | `[]` | no |
| <a name="input_firewall_tags"></a> [firewall\_tags](#input\_firewall\_tags) | Additional tags for the firewall | `map(string)` | `{}` | no |
| <a name="input_flow_log_bucket_arn"></a> [flow\_log\_bucket\_arn](#input\_flow\_log\_bucket\_arn) | Optional arn of s3 bucket destination for flow logs. If not specified, a bucket will be created. | `string` | `""` | no |
| <a name="input_home_net"></a> [home\_net](#input\_home\_net) | summary cidr block for all resources behind this egress vpc | `string` | `"10.0.0.0/8"` | no |
| <a name="input_http_ports"></a> [http\_ports](#input\_http\_ports) | Destination ports for HTTP traffic | `list(string)` | <pre>[<br>  "80"<br>]</pre> | no |
| <a name="input_igw_tags"></a> [igw\_tags](#input\_igw\_tags) | Additional tags for the internet gateway | `map(string)` | `{}` | no |
| <a name="input_kms_master_key_id"></a> [kms\_master\_key\_id](#input\_kms\_master\_key\_id) | AWS KMS master key id used for bucket and log storage encryption. If empty, this module will use the default AWS-managed kms service key. | `string` | `""` | no |
| <a name="input_log_retention_days"></a> [log\_retention\_days](#input\_log\_retention\_days) | Number of days to retain cloudwatch logs, default is 90 | `number` | `90` | no |
| <a name="input_name"></a> [name](#input\_name) | Name to be used on all the resources as identifier | `string` | `"anwf"` | no |
| <a name="input_nat_eip_tags"></a> [nat\_eip\_tags](#input\_nat\_eip\_tags) | Additional tags for the NAT EIP | `map(string)` | `{}` | no |
| <a name="input_nat_gateway_tags"></a> [nat\_gateway\_tags](#input\_nat\_gateway\_tags) | Additional tags for the NAT gateways | `map(string)` | `{}` | no |
| <a name="input_private_route_table_routes"></a> [private\_route\_table\_routes](#input\_private\_route\_table\_routes) | Configuration block of routes. See https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/default_route_table#route | `list(map(string))` | `[]` | no |
| <a name="input_public_acl_tags"></a> [public\_acl\_tags](#input\_public\_acl\_tags) | Additional tags for the public subnets network ACL | `map(string)` | `{}` | no |
| <a name="input_public_subnet_route_table_tags"></a> [public\_subnet\_route\_table\_tags](#input\_public\_subnet\_route\_table\_tags) | Additional tags for the public subnet route tables | `map(string)` | `{}` | no |
| <a name="input_public_subnet_suffix"></a> [public\_subnet\_suffix](#input\_public\_subnet\_suffix) | Suffix to append to public subnet name | `string` | `"public"` | no |
| <a name="input_public_subnet_tags"></a> [public\_subnet\_tags](#input\_public\_subnet\_tags) | Additional tags for the public subnets | `map(string)` | `{}` | no |
| <a name="input_public_subnets"></a> [public\_subnets](#input\_public\_subnets) | A list of public subnet cidr blocks inside the VPC | `list(string)` | `[]` | no |
| <a name="input_s3_log_bucket"></a> [s3\_log\_bucket](#input\_s3\_log\_bucket) | Name of s3 bucket for s3 bucket access logs | `string` | `""` | no |
| <a name="input_s3_logs"></a> [s3\_logs](#input\_s3\_logs) | send firewall logs to s3 bucket. If unset, logs will not be sent. Allowed values are "ALERT" and "FLOW". | `string` | `""` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to add to all resources | `map(string)` | `{}` | no |
| <a name="input_tls_ports"></a> [tls\_ports](#input\_tls\_ports) | Destination ports for TLS traffic | `list(string)` | <pre>[<br>  "443"<br>]</pre> | no |
| <a name="input_transit_gateway_acl_tags"></a> [transit\_gateway\_acl\_tags](#input\_transit\_gateway\_acl\_tags) | Additional tags for the transit gateway subnets network ACL | `map(string)` | `{}` | no |
| <a name="input_transit_gateway_id"></a> [transit\_gateway\_id](#input\_transit\_gateway\_id) | id of the transit gateway for tgw subnet attachment | `string` | n/a | yes |
| <a name="input_transit_gateway_subnet_route_table_tags"></a> [transit\_gateway\_subnet\_route\_table\_tags](#input\_transit\_gateway\_subnet\_route\_table\_tags) | Additional tags for the transit gateway subnet route tables | `map(string)` | `{}` | no |
| <a name="input_transit_gateway_subnet_suffix"></a> [transit\_gateway\_subnet\_suffix](#input\_transit\_gateway\_subnet\_suffix) | Suffix to append to transit gateway subnet name | `string` | `"transit-gateway"` | no |
| <a name="input_transit_gateway_subnet_tags"></a> [transit\_gateway\_subnet\_tags](#input\_transit\_gateway\_subnet\_tags) | Additional tags for the transit gateway subnets | `map(string)` | `{}` | no |
| <a name="input_transit_gateway_subnets"></a> [transit\_gateway\_subnets](#input\_transit\_gateway\_subnets) | A list of transit gateway attached subnet cidr blocks inside the VPC | `list(string)` | `[]` | no |
| <a name="input_vpc_flow_logs"></a> [vpc\_flow\_logs](#input\_vpc\_flow\_logs) | Log vpc traffic flows. If unset, vpc traffic flows will not be logged. If set, all vpc traffic will be logged. Allowed values are "CLOUDWATCH" and "S3". | `string` | `""` | no |
| <a name="input_vpc_tags"></a> [vpc\_tags](#input\_vpc\_tags) | Additional tags for the VPC | `map(string)` | `{}` | no |

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_log_group.alert](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_log_group.egress_vpc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_log_group.flow](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_default_network_acl.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/default_network_acl) | resource |
| [aws_default_security_group.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/default_security_group) | resource |
| [aws_ec2_transit_gateway_vpc_attachment.egress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway_vpc_attachment) | resource |
| [aws_eip.nat](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip) | resource |
| [aws_flow_log.egress_vpc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/flow_log) | resource |
| [aws_iam_role.flow_log](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.flow_log](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_internet_gateway.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway) | resource |
| [aws_nat_gateway.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/nat_gateway) | resource |
| [aws_network_acl.firewall](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl) | resource |
| [aws_network_acl.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl) | resource |
| [aws_network_acl.transit_gateway](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl) | resource |
| [aws_networkfirewall_firewall.egress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/networkfirewall_firewall) | resource |
| [aws_networkfirewall_firewall_policy.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/networkfirewall_firewall_policy) | resource |
| [aws_networkfirewall_logging_configuration.cloudwatch](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/networkfirewall_logging_configuration) | resource |
| [aws_networkfirewall_rule_group.stateful-egress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/networkfirewall_rule_group) | resource |
| [aws_networkfirewall_rule_group.stateless-egress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/networkfirewall_rule_group) | resource |
| [aws_route.firewall_subnet_default_route](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route.firewall_subnet_home_net_route](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route.public_home_net](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route.public_internet_gateway](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route.transit_gateway_subnet_default_route](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route_table.firewall_subnet](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table.public_subnet](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table.transit_gateway_subnet](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table_association.firewall](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_route_table_association.public_subnet](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_route_table_association.transit_gateway_subnet](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_s3_bucket.flow_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_logging.flow_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_logging) | resource |
| [aws_s3_bucket_public_access_block.block](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.crypto](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_versioning.versioning](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_subnet.firewall](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.transit_gateway](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_vpc.egress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc) | resource |
| [aws_availability_zones.azs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_ec2_transit_gateway.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ec2_transit_gateway) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_eni_lookup"></a> [eni\_lookup](#output\_eni\_lookup) | Provided for troubleshooting so you can access per-az maps of anwf enis |
| <a name="output_firewall_attachments"></a> [firewall\_attachments](#output\_firewall\_attachments) | output used to inspect firewall endpoint ids for route creation |
| <a name="output_network_firewall_endpoint_id"></a> [network\_firewall\_endpoint\_id](#output\_network\_firewall\_endpoint\_id) | Created Network Firewall endpoint id |
| <a name="output_transit_gateway_subnet_ids"></a> [transit\_gateway\_subnet\_ids](#output\_transit\_gateway\_subnet\_ids) | transit gateway subnet ids |
<!-- END_TF_DOCS -->