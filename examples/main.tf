module "egress_vpc" {
  source              = "../"
  cidr                = "10.1.1.0/24" # cidr shouldn't be bigger than /24
  home_net            = "10.0.0.0/8"
  firewall_policy_arn = aws_networkfirewall_firewall_policy.egress.arn

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
resource "aws_networkfirewall_firewall_policy" "egress" {
  name = "egress-policy"

  firewall_policy {
    stateless_default_actions          = ["aws:forward_to_sfe"]
    stateless_fragment_default_actions = ["aws:forward_to_sfe"]

    stateful_rule_group_reference {
      resource_arn = aws_networkfirewall_rule_group.domainlist.arn
    }

    stateless_rule_group_reference {
      priority     = 10
      resource_arn = aws_networkfirewall_rule_group.drop.arn
    }
  }
  tags = merge(
    {},
    var.tags
  )
}

resource "aws_networkfirewall_rule_group" "domainlist" {
  capacity = 1000
  name     = "domain-white-list"
  type     = "STATEFUL"

  rule_group {
    rules_source {
      rules_source_list {
        generated_rules_type = "ALLOWLIST"
        target_types = [
          "HTTP_HOST",
          "TLS_SNI"
        ]
        targets = [
          ".amazon.com",
          ".amazonaws.com",
          ".google.com",
          "slashdot.org"
        ]
      }
    }
  }
  tags = merge(
    {},
    var.tags
  )
}

variable "tags" {
  type = map(string)
  default = {
    costcenter = "12345"
  }
}

resource "aws_networkfirewall_rule_group" "drop" {
  capacity    = 10
  name        = "egress-drop"
  description = "stateless rule group that forwards http/s outbound traffic to stateful rules for inspection and drops all other traffic"
  type        = "STATELESS"

  rule_group {
    rules_source {
      stateless_rules_and_custom_actions {
        stateless_rule {
          priority = 10
          rule_definition {
            actions = ["aws:forward_to_sfe"]
            match_attributes {
              source {
                address_definition = "10.0.0.0/8"
              }
              source_port {
                from_port = 0
                to_port   = 65535
              }
              destination {
                address_definition = "0.0.0.0/0"
              }
              destination_port {
                from_port = 80
                to_port   = 80
              }
              destination_port {
                from_port = 443
                to_port   = 443
              }
              protocols = [6]
            }
          }
        }
        stateless_rule {
          priority = 100
          rule_definition {
            actions = ["aws:drop"]
            match_attributes {
              source {
                address_definition = "10.0.0.0/8"
              }
              destination {
                address_definition = "0.0.0.0/0"
              }
            }
          }
        }
      }
    }
  }
  tags = merge(
    {},
    var.tags
  )
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
