terraform {
  backend "s3" {
    bucket         = "ovr-tf-s3"
    key            = "app-ovr-infra/dev/terraform.tfstate"
    region         = "ap-south-1"
    use_lockfile   = true
    encrypt        = true
  }
}