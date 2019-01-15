module "vault_lb_aws" {
  # source = "github.com/hashicorp-modules/vault-lb-aws"
  source = "../../../vault-lb-aws"

  create      = false
  vpc_id      = ""
  cidr_blocks = []
  subnet_ids  = []
}
