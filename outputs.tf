output "azs" {
  value = data.aws_availability_zones.azs
}
output "availability_zone_names" {
  value = var.availability_zone_names[*]
}
