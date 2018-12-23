output "Vault West" {
  value = <<README

  ${format("export VAULT_ADDR=http://%s:8200", module.west.vault_lb_dns)}
  ${format("Vault UI: http://%s", module.west.vault_lb_dns)}
README
}

output "Vault East" {
  value = <<README

  ${format("export VAULT_ADDR=http://%s:8200", module.east.vault_lb_dns)}
  ${format("Vault UI: http://%s", module.east.vault_lb_dns)}
README
}
