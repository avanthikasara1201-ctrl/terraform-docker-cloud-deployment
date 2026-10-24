terraform {
  backend "s3" {
    bucket = "myterraform-state-us-west-1-075810104101"
    key    = "terraform.tfstate"
    region = "us-west-1"
  }
}

provider "aws" {
  region = "us-west-1"
}
