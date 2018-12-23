# ---------------------------------------------------------------------------------------------------------------------
# General Variables
# ---------------------------------------------------------------------------------------------------------------------
variable "name"         { default = "rchao-vault-dev" }
variable "ami_owner"    { default = "309956199498" } # Base RHEL owner
variable "ami_name"     { default = "*RHEL-7.3_HVM_GA-*" } # Base RHEL name
variable "local_ip_url" { default = "http://169.254.169.254/latest/meta-data/local-ipv4" }
variable "AWS_DEFAULT_REGION" { default = "us-east-1" } # Override ENV variables

# ---------------------------------------------------------------------------------------------------------------------
# Network Variables
# ---------------------------------------------------------------------------------------------------------------------
variable "vpc_cidr" { default = "10.140.0.0/16" }

variable "vpc_cidrs_public" {
  type    = "list"
  default = ["10.140.1.0/24", "10.140.2.0/24",]
}

variable "vpc_cidrs_private" {
  type    = "list"
  default = ["10.140.11.0/24", "10.140.12.0/24",]
}

variable "nat_count"        { default = 1 }
variable "bastion_servers"  { default = 0 }
variable "bastion_image_id" { default = "" }

variable "network_tags" {
  type    = "map"
  default = { }
}

# ---------------------------------------------------------------------------------------------------------------------
# Consul Variables
# ---------------------------------------------------------------------------------------------------------------------
variable "consul_install" { default = false }
variable "consul_version" { default = "1.2.0" }
variable "consul_url"     { default = "" }

variable "consul_config_override" { default = "" }

# ---------------------------------------------------------------------------------------------------------------------
# Vault Variables
# ---------------------------------------------------------------------------------------------------------------------
variable "vault_servers"  { default = 1 }
variable "vault_instance" { default = "t2.micro" }
variable "vault_version"  { default = "0.10.3" }
variable "vault_url"      { default = "https://s3-us-west-2.amazonaws.com/hc-enterprise-binaries/vault/ent/0.11.3/vault-enterprise_0.11.3%2Bent_linux_amd64.zip" } # Vault Enterprise download URL for runtime install, defaults to Vault OSS
variable "vault_image_id" { default = "" }

variable "vault_public" {
  description = "Assign a public IP, open port 22 for public access, & provision into public subnets to provide easier accessibility without a Bastion host - DO NOT DO THIS IN PROD"
  default     = true
}

variable "vault_config_override" { default = "" }

variable "vault_tags" {
  type    = "map"
  default = {"owner" = "rchaop", "TTL" = "-1"}
}

variable "vault_tags_list" {
  type    = "list"
  default = [
   {"key" = "owner", "value" = "rchao", "propagate_at_launch" = true},
   {"key" = "TTL", "value" = "-1", "propagate_at_launch" = true}
  ]
}
