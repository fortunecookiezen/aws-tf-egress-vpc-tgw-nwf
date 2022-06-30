output "transit_gateway_subnet_ids" {
  description = "transit gateway subnet ids"
  value       = toset(aws_subnet.transit_gateway[*].id)
}

# output "firewall_status" {
#   description = "output used to inspect firewall endpoint ids for route creation"
#   value       = aws_networkfirewall_firewall.egress.firewall_status[*]
# }

output "network_firewall_endpoint_id" {
  description = "Created Network Firewall endpoint id"
  value       = flatten(aws_networkfirewall_firewall.egress.firewall_status[*].sync_states[*].*.attachment[*])[*].endpoint_id
}
