resource "aws_vpc" "egress" {
  cidr_block           = var.cidr
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

  tags = merge(
    {
      "Name"   = format("%s-vpc", var.name)
      "Region" = format("%s", data.aws_region.current.name)
    },
    var.tags,
    var.vpc_tags,
  )
}

# manage the default security group, no ingress or egress mean no rules
resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.egress.id
  tags = merge(
    {
      "Name" = "default"
    },
    var.tags,
  )
}

#manage the default network acl to detect drift
resource "aws_default_network_acl" "default" {
  default_network_acl_id = aws_vpc.egress.default_network_acl_id

  ingress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = aws_vpc.egress.cidr_block
    from_port  = 0
    to_port    = 0
  }

  egress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
  tags = merge(
    {
      "Name" = "default"
    },
    var.tags,
  )
}

#
# FLOW LOGS
#

resource "aws_flow_log" "egress_vpc" {
  count                    = var.vpc_flow_logs != "" ? 1 : 0
  iam_role_arn             = var.vpc_flow_logs == "CLOUDWATCH" ? aws_iam_role.flow_log[0].arn : null
  log_destination_type     = var.vpc_flow_logs == "CLOUDWATCH" ? "cloud-watch-logs" : "s3"
  log_destination          = var.vpc_flow_logs == "CLOUDWATCH" ? aws_cloudwatch_log_group.egress_vpc[0].arn : (var.flow_log_bucket_arn != "" ? var.flow_log_bucket_arn : aws_s3_bucket.flow_logs[0].arn)
  max_aggregation_interval = var.vpc_flow_logs == "CLOUDWATCH" ? 60 : 600
  traffic_type             = "ALL"
  vpc_id                   = aws_vpc.egress.id

  tags = merge(
    {
      Name = format("%s-vpc", var.name)
    },
    var.tags,
  )
}

resource "aws_s3_bucket" "flow_logs" {
  count  = var.vpc_flow_logs == "S3" && var.flow_log_bucket_arn == "" ? 1 : 0
  bucket = lower("${var.prefix}-${var.name}-flow-logs-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}")


  tags = merge(
    var.tags,
    var.bucket_tags
  )
}

resource "aws_s3_bucket_logging" "flow_logs" {
  count         = var.vpc_flow_logs == "S3" && var.s3_log_bucket != "" ? 1 : 0
  bucket        = aws_s3_bucket.flow_logs[0].id
  target_bucket = var.s3_log_bucket
  target_prefix = "${aws_s3_bucket.flow_logs[0].id}/"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "crypto" {
  count  = var.vpc_flow_logs == "S3" && var.flow_log_bucket_arn == "" ? 1 : 0
  bucket = aws_s3_bucket.flow_logs[0].id
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.kms_master_key_id != "" ? var.kms_master_key_id : null
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_versioning" "versioning" {
  count  = var.vpc_flow_logs == "S3" && var.flow_log_bucket_arn == "" ? 1 : 0
  bucket = aws_s3_bucket.flow_logs[0].id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "block" {
  count                   = var.vpc_flow_logs == "S3" && var.flow_log_bucket_arn == "" ? 1 : 0
  bucket                  = aws_s3_bucket.flow_logs[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_cloudwatch_log_group" "egress_vpc" {
  count             = var.vpc_flow_logs == "CLOUDWATCH" ? 1 : 0
  name              = "vpc-flowlogs/${var.name}"
  retention_in_days = var.log_retention_days
}

resource "aws_iam_role" "flow_log" {
  count       = var.vpc_flow_logs == "CLOUDWATCH" ? 1 : 0
  name_prefix = "${var.prefix}-${var.name}-flow-log-"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })
  tags = merge(
    var.tags,
  )
}

# tfsec:ignore:aws-iam-no-policy-wildcards
resource "aws_iam_role_policy" "flow_log" {
  count = var.vpc_flow_logs == "CLOUDWATCH" ? 1 : 0
  role  = aws_iam_role.flow_log[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

#
# GATEWAYS
#

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.egress.id

  tags = merge(
    {
      "Name" = format("%s", var.name)
    },
    var.tags,
    var.igw_tags,
  )
}

resource "aws_eip" "nat" {
  count = (length(var.availability_zone_names))

  vpc = true

  tags = merge(
    {
      "Name" = format(
        "${var.name}-%s",
        element(var.availability_zone_names, count.index),
      )
    },
    var.tags,
    var.nat_eip_tags,
  )
}

resource "aws_nat_gateway" "this" {
  count = (length(var.availability_zone_names))

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(
    {
      "Name" = format(
        "${var.name}-%s",
        element(var.availability_zone_names, count.index),
      )
    },
    var.tags,
    var.nat_gateway_tags,
  )

  depends_on = [aws_internet_gateway.this]
}

#
# AMAZON NETWORK FIREWALL
# 

resource "aws_networkfirewall_firewall" "egress" {
  name                = var.name
  firewall_policy_arn = var.firewall_policy_arn != "" ? var.firewall_policy_arn : aws_networkfirewall_firewall_policy.default.arn
  vpc_id              = aws_vpc.egress.id

  dynamic "subnet_mapping" {
    for_each = tolist(aws_subnet.firewall.*.id)
    content {
      subnet_id = subnet_mapping.value
    }
  }

  tags = merge(var.tags, var.firewall_tags)
}

resource "aws_networkfirewall_firewall_policy" "default" {
  name = "default-egress-policy"

  firewall_policy {
    stateless_default_actions          = ["aws:forward_to_sfe"]
    stateless_fragment_default_actions = ["aws:forward_to_sfe"]

    stateful_rule_group_reference {
      resource_arn = aws_networkfirewall_rule_group.stateful-egress.arn
    }

    stateless_rule_group_reference {
      priority     = 10
      resource_arn = aws_networkfirewall_rule_group.stateless-egress.arn
    }

    # managed rule groups don't work in this use case because $HOME_NET is the vpc cidr and cannot be configured to a different value
    # but, this it what it would look like if it could

    # stateful_rule_group_reference {
    #   resource_arn = "arn:aws:network-firewall:us-east-1:aws-managed:stateful-rulegroup/AbusedLegitBotNetCommandAndControlDomainsActionOrder"
    # }
    # stateful_rule_group_reference {
    #   resource_arn = "arn:aws:network-firewall:us-east-1:aws-managed:stateful-rulegroup/AbusedLegitMalwareDomainsActionOrder"
    # }
    # stateful_rule_group_reference {
    #   resource_arn = "arn:aws:network-firewall:us-east-1:aws-managed:stateful-rulegroup/BotNetCommandAndControlDomainsActionOrder"
    # }
    # stateful_rule_group_reference {
    #   resource_arn = "arn:aws:network-firewall:us-east-1:aws-managed:stateful-rulegroup/MalwareDomainsActionOrder"
    # }
    # stateful_rule_group_reference {
    #   resource_arn = "arn:aws:network-firewall:us-east-1:aws-managed:stateful-rulegroup/ThreatSignaturesBotnetActionOrder"
    # }
    # stateful_rule_group_reference {
    #   resource_arn = "arn:aws:network-firewall:us-east-1:aws-managed:stateful-rulegroup/ThreatSignaturesBotnetWebActionOrder"
    # }
    # stateful_rule_group_reference {
    #   resource_arn = "arn:aws:network-firewall:us-east-1:aws-managed:stateful-rulegroup/ThreatSignaturesBotnetWindowsActionOrder"
    # }
    # stateful_rule_group_reference {
    #   resource_arn = "arn:aws:network-firewall:us-east-1:aws-managed:stateful-rulegroup/ThreatSignaturesDoSActionOrder"
    # }
    # stateful_rule_group_reference {
    #   resource_arn = "arn:aws:network-firewall:us-east-1:aws-managed:stateful-rulegroup/ThreatSignaturesEmergingEventsActionOrder"
    # }
    # stateful_rule_group_reference {
    #   resource_arn = "arn:aws:network-firewall:us-east-1:aws-managed:stateful-rulegroup/ThreatSignaturesExploitsActionOrder"
    # }
    # stateful_rule_group_reference {
    #   resource_arn = "arn:aws:network-firewall:us-east-1:aws-managed:stateful-rulegroup/ThreatSignaturesFUPActionOrder"
    # }
    # stateful_rule_group_reference {
    #   resource_arn = "arn:aws:network-firewall:us-east-1:aws-managed:stateful-rulegroup/ThreatSignaturesIOCActionOrder"
    # }
    # stateful_rule_group_reference {
    #   resource_arn = "arn:aws:network-firewall:us-east-1:aws-managed:stateful-rulegroup/ThreatSignaturesMalwareActionOrder"
    # }
    # stateful_rule_group_reference {
    #   resource_arn = "arn:aws:network-firewall:us-east-1:aws-managed:stateful-rulegroup/ThreatSignaturesMalwareWebActionOrder"
    # }

  }
  tags = merge(var.tags, var.firewall_policy_tags)
}

resource "aws_networkfirewall_rule_group" "stateful-egress" {
  capacity    = 10
  name        = "default-stateful-egress-rule"
  description = "stateful egress firewall rule group that allows http/s outbound traffic on ports 80 and 443 to any address"
  type        = "STATEFUL"

  rule_group {
    rule_variables {
      ip_sets {
        key = "HOME_NET"
        ip_set {
          definition = ["${var.home_net}"]
        }
      }
      port_sets {
        key = "HTTP_PORTS"
        port_set {
          definition = var.http_ports
        }
      }
      port_sets {
        key = "TLS_PORTS"
        port_set {
          definition = var.tls_ports
        }
      }
    }
    rules_source {
      stateful_rule {
        action = "PASS"
        header {
          destination      = "Any"
          destination_port = "$HTTP_PORTS"
          direction        = "FORWARD"
          protocol         = "HTTP"
          source           = "$HOME_NET"
          source_port      = "Any"
        }
        rule_option {
          keyword = "sid:1"
        }
      }
      stateful_rule {
        action = "PASS"
        header {
          destination      = "Any"
          destination_port = "$TLS_PORTS"
          direction        = "FORWARD"
          protocol         = "TLS"
          source           = "$HOME_NET"
          source_port      = "Any"
        }
        rule_option {
          keyword = "sid:2"
        }
      }
    }
    stateful_rule_options {
      rule_order = "DEFAULT_ACTION_ORDER"
    }
  }
  tags = merge(
    {
      "Name" = format(
        "%s-firewall-rule-group", var.name
      )
    },
  var.tags, var.firewall_tags)
}

resource "aws_networkfirewall_rule_group" "stateless-egress" {
  capacity    = 10
  name        = "default-stateless-egress-rule-group"
  description = "stateless rule group that forwards http/s outbound traffic to stateful rules for inspection and drops all other traffic"
  type        = "STATELESS"

  rule_group {
    rules_source {
      stateless_rules_and_custom_actions {
        stateless_rule {
          priority = 1
          rule_definition {
            actions = ["aws:forward_to_sfe"]
            match_attributes {
              source {
                address_definition = var.home_net
              }
              source_port {
                from_port = 0
                to_port   = 65535
              }
              destination {
                address_definition = "0.0.0.0/0"
              }
              dynamic "destination_port" {
                for_each = flatten([var.http_ports, var.tls_ports])
                content {
                  from_port = destination_port.value
                  to_port   = destination_port.value
                }
              }
              protocols = [6]
            }
          }
        }
        stateless_rule {
          priority = 10
          rule_definition {
            actions = ["aws:drop"]
            match_attributes {
              source {
                address_definition = var.home_net
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
    {
      "Name" = format(
        "%s-firewall-rule-group", var.name
      )
    },
  var.tags, var.firewall_tags)
}

resource "aws_cloudwatch_log_group" "flow" {
  name              = "/aws/${var.firewall_log_group_name}/flow"
  retention_in_days = var.log_retention_days
}

resource "aws_cloudwatch_log_group" "alert" {
  name              = "/aws/${var.firewall_log_group_name}/alert"
  retention_in_days = var.log_retention_days
}

resource "aws_networkfirewall_logging_configuration" "cloudwatch" {
  firewall_arn = aws_networkfirewall_firewall.egress.arn

  logging_configuration {
    log_destination_config {
      log_destination = {
        logGroup = aws_cloudwatch_log_group.alert.name
      }
      log_destination_type = "CloudWatchLogs"
      log_type             = "ALERT"
    }
    log_destination_config {
      log_destination = {
        logGroup = aws_cloudwatch_log_group.flow.name
      }
      log_destination_type = "CloudWatchLogs"
      log_type             = "FLOW"
    }
  }
}

#
# NAT GATEWAY (public) SUBNETS
#
resource "aws_subnet" "public" {
  count = (length(var.availability_zone_names) <= length(data.aws_availability_zones.azs)) ? length(var.availability_zone_names) : 0

  vpc_id                          = aws_vpc.egress.id
  cidr_block                      = var.public_subnets[count.index]
  availability_zone               = var.availability_zone_names[count.index]
  map_public_ip_on_launch         = false
  assign_ipv6_address_on_creation = false

  tags = merge(
    {
      "Name" = format(
        "%s-${var.public_subnet_suffix}-%s",
        var.name,
        var.availability_zone_names[count.index]
      )
    },
    var.tags,
    var.public_subnet_tags,
  )
}

#
# NETWORK FIREWALL (firewall) SUBNETS
#

resource "aws_subnet" "firewall" {
  count = (length(var.availability_zone_names) <= length(data.aws_availability_zones.azs)) ? length(var.availability_zone_names) : 0

  vpc_id                          = aws_vpc.egress.id
  cidr_block                      = var.firewall_subnets[count.index]
  availability_zone               = var.availability_zone_names[count.index]
  assign_ipv6_address_on_creation = false

  tags = merge(
    {
      "Name" = format(
        "%s-${var.firewall_subnet_suffix}-%s",
        var.name,
        var.availability_zone_names[count.index]
      )
    },
    var.tags,
    var.firewall_subnet_tags,
  )
}

#
# TRANSIT GATEWAY (TGW) SUBNETS
#

resource "aws_subnet" "transit_gateway" {
  count = (length(var.availability_zone_names) <= length(data.aws_availability_zones.azs)) ? length(var.availability_zone_names) : 0

  vpc_id                          = aws_vpc.egress.id
  cidr_block                      = var.transit_gateway_subnets[count.index]
  availability_zone               = var.availability_zone_names[count.index]
  assign_ipv6_address_on_creation = false

  tags = merge(
    {
      "Name" = format(
        "%s-${var.transit_gateway_subnet_suffix}-%s",
        var.name,
        var.availability_zone_names[count.index]
      )
    },
    var.tags,
    var.transit_gateway_subnet_tags,
  )
}

resource "aws_ec2_transit_gateway_vpc_attachment" "egress" {
  subnet_ids         = toset(aws_subnet.transit_gateway[*].id)
  transit_gateway_id = data.aws_ec2_transit_gateway.this.id
  vpc_id             = aws_vpc.egress.id

  appliance_mode_support                          = "enable"
  dns_support                                     = "enable"
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false

  tags = {
    Name = var.name
  }
}

#
# PUBLIC ROUTES
#

resource "aws_route_table" "public_subnet" {
  count = length(var.public_subnets)

  vpc_id = aws_vpc.egress.id

  tags = merge(
    {
      "Name" = format("%s-${var.public_subnet_suffix}-%s", var.name, var.availability_zone_names[count.index])
    },
    var.tags,
    var.public_subnet_route_table_tags,
  )
}

resource "aws_route_table_association" "public_subnet" {
  count = length(var.public_subnets)

  subnet_id      = element(aws_subnet.public.*.id, count.index)
  route_table_id = element(aws_route_table.public_subnet.*.id, count.index)
}


resource "aws_route" "public_internet_gateway" {
  count = length(var.public_subnets)

  route_table_id         = element(aws_route_table.public_subnet.*.id, count.index)
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id

  timeouts {
    create = "5m"
  }
}

resource "aws_route" "public_home_net" {
  count = length(var.public_subnets)

  route_table_id         = element(aws_route_table.public_subnet.*.id, count.index)
  destination_cidr_block = var.home_net
  vpc_endpoint_id        = lookup(local.vpce_lookup, var.availability_zone_names[count.index])

  timeouts {
    create = "5m"
  }
}

#
# FIREWALL SUBNET ROUTES
#

resource "aws_route_table" "firewall_subnet" {
  count = length(var.firewall_subnets)

  vpc_id = aws_vpc.egress.id

  tags = merge(
    {
      "Name" = format("%s-${var.firewall_subnet_suffix}-%s", var.name, var.availability_zone_names[count.index])
    },
    var.tags,
    var.firewall_subnet_route_table_tags,
  )
}

resource "aws_route_table_association" "firewall" {
  count = length(var.firewall_subnets)

  subnet_id      = element(aws_subnet.firewall.*.id, count.index)
  route_table_id = element(aws_route_table.firewall_subnet.*.id, count.index)
}

resource "aws_route" "firewall_subnet_default_route" {
  count = length(var.firewall_subnets)

  route_table_id         = element(aws_route_table.firewall_subnet.*.id, count.index)
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[count.index].id

  timeouts {
    create = "5m"
  }
}

resource "aws_route" "firewall_subnet_home_net_route" {
  count = length(var.firewall_subnets)

  route_table_id         = element(aws_route_table.firewall_subnet.*.id, count.index)
  destination_cidr_block = var.home_net
  transit_gateway_id     = data.aws_ec2_transit_gateway.this.id

  timeouts {
    create = "5m"
  }
}


#
# TRANSIT GATEWAY SUBNET ROUTES
#

resource "aws_route_table" "transit_gateway_subnet" {
  count = length(var.transit_gateway_subnets)

  vpc_id = aws_vpc.egress.id

  tags = merge(
    {
      "Name" = format("%s-${var.transit_gateway_subnet_suffix}-%s", var.name, var.availability_zone_names[count.index])
    },
    var.tags,
    var.transit_gateway_subnet_route_table_tags,
  )
}

resource "aws_route_table_association" "transit_gateway_subnet" {
  count = length(var.transit_gateway_subnets)

  subnet_id      = element(aws_subnet.transit_gateway.*.id, count.index)
  route_table_id = element(aws_route_table.transit_gateway_subnet.*.id, count.index)
}

resource "aws_route" "transit_gateway_subnet_default_route" {
  count = length(var.transit_gateway_subnets)

  route_table_id         = element(aws_route_table.transit_gateway_subnet.*.id, count.index)
  destination_cidr_block = "0.0.0.0/0"
  vpc_endpoint_id        = lookup(local.vpce_lookup, var.availability_zone_names[count.index])

  timeouts {
    create = "5m"
  }
}

#
# NACLS - we don't really use these for access control, so they're pretty loose.
#

resource "aws_network_acl" "public" {
  count = length(var.public_subnets) > 0 ? 1 : 0

  vpc_id     = aws_vpc.egress.id
  subnet_ids = aws_subnet.public.*.id

  ingress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  egress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = merge(
    {
      "Name" = format("%s-${var.public_subnet_suffix}-nacl", var.name)
    },
    var.tags,
    var.public_acl_tags,
  )
}

resource "aws_network_acl" "firewall" {
  count = length(var.firewall_subnets) > 0 ? 1 : 0

  vpc_id     = aws_vpc.egress.id
  subnet_ids = aws_subnet.firewall.*.id

  ingress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  egress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = merge(
    {
      "Name" = format("%s-${var.firewall_subnet_suffix}-nacl", var.name)
    },
    var.tags,
    var.firewall_acl_tags,
  )
}

resource "aws_network_acl" "transit_gateway" {
  count = length(var.transit_gateway_subnets) > 0 ? 1 : 0

  vpc_id     = aws_vpc.egress.id
  subnet_ids = aws_subnet.transit_gateway.*.id

  ingress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0" #or else your traffic gets rejected by the tgw attachment https://docs.aws.amazon.com/vpc/latest/tgw/tgw-nacls.html
    from_port  = 0
    to_port    = 0
  }

  egress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = merge(
    {
      "Name" = format("%s-${var.transit_gateway_subnet_suffix}-nacl", var.name)
    },
    var.tags,
    var.transit_gateway_acl_tags,
  )
}
