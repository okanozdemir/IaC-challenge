# Terraform provider

# Rancher
provider "rancher2" {
  api_url = var.RANCHER_URL
  token_key = var.RANCHER_TOKEN
  insecure = true
}

provider "aws" {
  region = var.AWS_REGION
}
