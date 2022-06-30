resource "aws_vpc" "egress" {
  cidr_block           = var.cidr
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

  tags = merge(
    {
      "Name"   = format("%s", var.name)
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
    stateless_default_actions          = ["aws:pass"]
    stateless_fragment_default_actions = ["aws:drop"]
  }
  tags = merge(var.tags, var.firewall_policy_tags)
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
}

#
# PUBLIC ROUTES
#

resource "aws_route_table" "public_subnet" {
  count = length(var.public_subnets)

  vpc_id = aws_vpc.egress.id

  tags = merge(
    {
      "Name" = format("%s-${var.public_subnet_suffix}-rt", var.name)
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
  vpc_endpoint_id        = flatten(aws_networkfirewall_firewall.egress.firewall_status[*].sync_states[*].*.attachment[*])[count.index].endpoint_id

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
      "Name" = format("%s-${var.firewall_subnet_suffix}-rt", var.name)
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
      "Name" = format("%s-${var.transit_gateway_subnet_suffix}-rt", var.name)
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


# resource "aws_route" "transit_gateway_subnet_default_route" {
#   count = length(var.transit_gateway_subnets)

#   route_table_id         = element(aws_route_table.transit_gateway.*.id, count.index)
#   destination_cidr_block = "0.0.0.0/0"
#   nat_gateway_id         = aws_nat_gateway.this[count.index].id

#   timeouts {
#     create = "5m"
#   }
# }

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
    cidr_block = var.home_net
    from_port  = 0
    to_port    = 0
  }

  egress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0" #leaving this here so it can talk to s3 gateway endpoints
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
