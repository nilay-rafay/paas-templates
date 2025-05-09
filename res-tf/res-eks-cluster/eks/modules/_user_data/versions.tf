terraform {
  required_version = ">=1.3.2"

  required_providers {
    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = "2.3.5"
    }
    null = {
      source  = "hashicorp/null"
      version = "3.2.3"
    }
  }
}
