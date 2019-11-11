resource "aws_s3_bucket" "bucket" {
    bucket = "devlimabucketexample"
    acl    = "private"

    versioning{
        enabled = true
    }

    tags = {
        Env = "Demo"
    }
  
}
