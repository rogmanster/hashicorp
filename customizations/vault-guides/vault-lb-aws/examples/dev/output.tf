output "vault_lb_sg_id" {
  value = "${module.vault_lb_aws.vault_lb_sg_id}"
}

output "vault_lb_dns" {
  value = "${module.vault_lb_aws.vault_lb_dns}"
}

output "vault_tg_http_8200_arn" {
  value = "${module.vault_lb_aws.vault_tg_http_8200_arn}"
}
