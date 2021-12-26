terraform {
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "whos-home"

    workspaces {
      name = "whos-home"
    }
  }
}
