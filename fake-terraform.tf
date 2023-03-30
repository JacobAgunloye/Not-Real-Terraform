resource "aws_s3_bucket" "foo-bucket" {
  region        = var.region
  bucket        = local.bucket_name
  force_destroy = true
  acl           = "public-read"
}

resource "aws_s3_bucket" "bar-bucket" {
  region        = var.region
  bucket        = local.bucket_name
  force_destroy = true
  
tags = {
    Name = "bar-${data.aws_caller_identity.current.account_id}"
  }
  versioning {
    enabled = true
  }
  logging {
    target_bucket = "${aws_s3_bucket.log_bucket.id}"
    target_prefix = "log/"
  }
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = "${aws_kms_key.mykey.arn}"
        sse_algorithm     = "aws:kms"
      }
    }
  }
  acl           = "private"
}

resource "aws_key_pair" "public_ec2_key" {
    key_name = "terraform_ec2_key"
    public_key = file("~/fake/random-ssh.pub")
    tags = var.tags
}

resource "aws_security_group" "public_ec2_foo_security_groups" {
  name        = "public_firewall"
  description = "fake terraform"

  ingress {
    description = "TLS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks =  ["0.0.0.0/0"]
  }
 
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

resource "aws_instance" foo_ec2" {
    ami = var.ami
    instance_type = var.instance_type
    key_name = aws_key_pair.public_ec2_key.key_name
    security_groups = ["public_firewall"]
    tags = var.tags
}
