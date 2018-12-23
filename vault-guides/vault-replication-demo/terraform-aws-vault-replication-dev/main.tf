provider "aws" {
  region     = "us-east-1"
}

provider "aws" {
  alias  = "us-w2"
  region = "us-west-2"
}

module "east" {
  source = "./east"
}

module "west" {
  source = "./west"
  providers = {
    aws = "aws.us-w2"
  }
}
