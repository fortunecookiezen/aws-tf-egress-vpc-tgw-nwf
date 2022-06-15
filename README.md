# AWS Central Egress VPC with Network Firewall

## Description

Terraform code to create a central egress vpc using nat gateway and aws network firewall as documented by aws in [Building a Scalable and Secure Multi-VPC AWS Network Infrastructure](https://docs.aws.amazon.com/whitepapers/latest/building-scalable-secure-multi-vpc-network-infrastructure/using-nat-gateway-with-firewall.html)

## Diagram

![Diagram](https://docs.aws.amazon.com/whitepapers/latest/building-scalable-secure-multi-vpc-network-infrastructure/images/centralized-egress-rt.png)


<!-- BEGIN_TF_DOCS -->


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
| <a name="input_cidr"></a> [cidr](#input\_cidr) | cidr block for this vpc. It really doesn't need to be larger than /24. | `string` | n/a | yes |
| <a name="input_enable_dns_hostnames"></a> [enable\_dns\_hostnames](#input\_enable\_dns\_hostnames) | Should be true to enable DNS hostnames in the VPC | `bool` | `true` | no |
| <a name="input_enable_dns_support"></a> [enable\_dns\_support](#input\_enable\_dns\_support) | Should be true to enable DNS support in the VPC | `bool` | `true` | no |
| <a name="input_firewall_acl_tags"></a> [firewall\_acl\_tags](#input\_firewall\_acl\_tags) | Additional tags for the firewall subnets network ACL | `map(string)` | `{}` | no |
| <a name="input_firewall_route_table_tags"></a> [firewall\_route\_table\_tags](#input\_firewall\_route\_table\_tags) | Additional tags for the firewall subnet route tables | `map(string)` | `{}` | no |
| <a name="input_firewall_subnet_suffix"></a> [firewall\_subnet\_suffix](#input\_firewall\_subnet\_suffix) | Suffix to append to firewall subnet name | `string` | `"nwf"` | no |
| <a name="input_firewall_subnet_tags"></a> [firewall\_subnet\_tags](#input\_firewall\_subnet\_tags) | Additional tags for the firewall subnets | `map(string)` | `{}` | no |
| <a name="input_firewall_subnets"></a> [firewall\_subnets](#input\_firewall\_subnets) | A list of firewall subnet cidr blocks inside the VPC | `list(string)` | `[]` | no |
| <a name="input_home_net"></a> [home\_net](#input\_home\_net) | summary cidr block for all resources behind this egress vpc | `string` | `"10.0.0.0/8"` | no |
| <a name="input_igw_tags"></a> [igw\_tags](#input\_igw\_tags) | Additional tags for the internet gateway | `map(string)` | `{}` | no |
| <a name="input_name"></a> [name](#input\_name) | Name to be used on all the resources as identifier | `string` | `"egress-vpc"` | no |
| <a name="input_private_route_table_routes"></a> [private\_route\_table\_routes](#input\_private\_route\_table\_routes) | Configuration block of routes. See https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/default_route_table#route | `list(map(string))` | `[]` | no |
| <a name="input_public_acl_tags"></a> [public\_acl\_tags](#input\_public\_acl\_tags) | Additional tags for the public subnets network ACL | `map(string)` | `{}` | no |
| <a name="input_public_route_table_tags"></a> [public\_route\_table\_tags](#input\_public\_route\_table\_tags) | Additional tags for the public subnet route tables | `map(string)` | `{}` | no |
| <a name="input_public_subnet_suffix"></a> [public\_subnet\_suffix](#input\_public\_subnet\_suffix) | Suffix to append to public subnet name | `string` | `"public"` | no |
| <a name="input_public_subnet_tags"></a> [public\_subnet\_tags](#input\_public\_subnet\_tags) | Additional tags for the public subnets | `map(string)` | `{}` | no |
| <a name="input_public_subnets"></a> [public\_subnets](#input\_public\_subnets) | A list of public subnet cidr blocks inside the VPC | `list(string)` | `[]` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to add to all resources | `map(string)` | `{}` | no |
| <a name="input_transit_gateway_acl_tags"></a> [transit\_gateway\_acl\_tags](#input\_transit\_gateway\_acl\_tags) | Additional tags for the transit gateway subnets network ACL | `map(string)` | `{}` | no |
| <a name="input_transit_gateway_route_table_tags"></a> [transit\_gateway\_route\_table\_tags](#input\_transit\_gateway\_route\_table\_tags) | Additional tags for the transit gateway subnet route tables | `map(string)` | `{}` | no |
| <a name="input_transit_gateway_subnet_suffix"></a> [transit\_gateway\_subnet\_suffix](#input\_transit\_gateway\_subnet\_suffix) | Suffix to append to transit gateway subnet name | `string` | `"tgw"` | no |
| <a name="input_transit_gateway_subnet_tags"></a> [transit\_gateway\_subnet\_tags](#input\_transit\_gateway\_subnet\_tags) | Additional tags for the transit gateway subnets | `map(string)` | `{}` | no |
| <a name="input_transit_gateway_subnets"></a> [transit\_gateway\_subnets](#input\_transit\_gateway\_subnets) | A list of transit gateway attached subnet cidr blocks inside the VPC | `list(string)` | `[]` | no |
| <a name="input_vpc_tags"></a> [vpc\_tags](#input\_vpc\_tags) | Additional tags for the VPC | `map(string)` | `{}` | no |

## Resources

| Name | Type |
|------|------|
| [aws_default_network_acl.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/default_network_acl) | resource |
| [aws_default_security_group.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/default_security_group) | resource |
| [aws_network_acl.firewall](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl) | resource |
| [aws_network_acl.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl) | resource |
| [aws_network_acl.transit_gateway](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl) | resource |
| [aws_subnet.firewall](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.transit_gateway](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_vpc.egress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc) | resource |
| [aws_availability_zones.azs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Outputs

No outputs.
<!-- END_TF_DOCS -->