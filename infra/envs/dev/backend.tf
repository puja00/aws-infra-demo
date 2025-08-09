terraform {
  backend "s3" {
    bucket         = "terraform-s3-bucket000"
    key            = "envs/dev/terraform.tfstate"
    region         = "us-east-2"
    dynamodb_table = "tf-locks"
    encrypt        = true
  }
}