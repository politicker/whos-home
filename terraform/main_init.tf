terraform {
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "whos-home"

    workspaces {
      name = "whos-whome"
    }
  }
}


provider "aws" {
  region  = "us-east-2"
  profile = "whos-home"
}
