provider "aws" {
  region     = "us-east-2"
  access_key = "xxxxxxxxxxxxxxx"
  secret_key = "${var.secret_key}"
}

module "s3_bucket" {
  source = "./s3-webstatic"
}

