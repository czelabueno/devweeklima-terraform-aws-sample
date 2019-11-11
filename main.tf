provider "aws" {
  region     = "us-east-2"
  access_key = "AKIA2I76K2F2PBL3L4NS"
  secret_key = "${var.secret_key}"
}

module "s3_bucket" {
  source = "./s3-webstatic"
}

