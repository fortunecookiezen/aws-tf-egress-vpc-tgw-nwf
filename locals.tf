locals {
  eni_lookup = { for state in aws_networkfirewall_firewall.egress.firewall_status[0].sync_states : state.availability_zone => state.attachment[0].endpoint_id }
}
