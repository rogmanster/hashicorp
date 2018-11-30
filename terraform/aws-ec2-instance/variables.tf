variable "aws_region" {
  description = "AWS region"
  default = "us-west-2"
}

variable "aws_profile" {
  description = "AWS profile used for provider connection"
  default = "default"
}

variable "ami_id" {
  description = "ID of the AMI to provision. Default is Ubuntu 18.04 Base Image"
  default = "ami-00d5c4c42b11e4aba"
}

variable "instance_type" {
  description = "type of EC2 instance to provision."
  default = "t2.micro"
}

variable "name" {
  description = "name to pass to Name tag"
  default = "rogmanster"
}

variable "owner" {
  description = "Name to pass to the Owner tag"
  default = "rchao"
}

variable "ttl" {
  description = "Hours until instances are reaped by N.E.P.T.R"
  default = "3"
}

variable "description" {
  description = "So meta"
  default = "Foo"
}
