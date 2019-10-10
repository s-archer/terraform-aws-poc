
# --- BIG-IP Management Public IP Addresses
output "mgmt_public_ips" {
  value = module.bigip.mgmt_public_ips
}

# --- BIG-IP Management Public DNS
output "mgmt_public_dns" {
  value = module.bigip.mgmt_public_dns
}

# --- BIG-IP Password
output "password" {
  value = module.bigip.password
}

