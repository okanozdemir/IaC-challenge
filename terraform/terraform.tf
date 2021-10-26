# Terraform backend configuration

terraform {
  backend "s3" {
    bucket = "ooz-terraform"
    key    = "states"
    region = "eu-central-1"
  }
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.1"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.1"
    }
    rancher2 = {
      source  = "rancher/rancher2"
      version = "~> 1.21"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
}

