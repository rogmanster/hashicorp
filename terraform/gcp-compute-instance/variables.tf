variable "gcp_credentials" {
  description = "GCP credentials needed by google provider"
}

variable "gcp_project" {
  description = "GCP project name"
}

variable "gcp_region" {
  description = "GCP region, e.g. us-east1"
  default = "us-west1"
}

variable "gcp_zone" {
  description = "GCP zone, e.g. us-east1-a"
  default = "us-west1-b"
}

variable "machine_type" {
  description = "GCP machine type"
  default = "n1-standard-1"
}

variable "instance_name" {
  description = "GCP instance name"
  default = "rogmanster"
}

variable "image" {
  description = "image to build instance from"
  default = "debian-cloud/debian-8"
}
