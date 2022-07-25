output "transit_gateway_subnet_ids" {
  description = "transit gateway subnet ids"
  value       = toset(aws_subnet.transit_gateway[*].id)
}

output "firewall_attachments" {
  description = "output used to inspect firewall endpoint ids for route creation"
  value       = flatten(aws_networkfirewall_firewall.egress.firewall_status[0].sync_states[*].attachment[0])
}

output "network_firewall_endpoint_id" {
  description = "Created Network Firewall endpoint id"
  value       = flatten(aws_networkfirewall_firewall.egress.firewall_status[*].sync_states[*].*.attachment[*])[*].endpoint_id
}

output "eni_lookup" {
  description = "Provided for troubleshooting so you can access per-az maps of anwf enis"
  value       = local.eni_lookup
}
