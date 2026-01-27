terraform {
  backend "s3" {
    bucket = "ayub-bucket21"
    key    = "terraform.tfstate"
    region = "eu-west-2"
  }
}
