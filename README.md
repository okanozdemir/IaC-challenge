# IaC-challenge

## Requirements

- [Rancher 2](https://rancher.com/quick-start) and its API credentials
- AWS Credentials
- S3 bucket to save terraform states
- The following environment variables should be created as Github secrets. 
```
TF_VAR_AWS_ACCESS_KEY_ID="XXXXXX"
TF_VAR_aws_account_id="AWS_ACCOUNT_ID"
TF_VAR_AWS_SECRET_ACCESS_KEY="XXXXXX"
TF_VAR_aws_region="eu-central-1"
TF_VAR_rancher_token="USER:TOKEN"
TF_VAR_rancher_url="https://URL"
TF_VAR_ecr_name="ECR"
MYSQL_PASSWORD="passwd"
```

## Usage

Configure the Terraform [variables](https://github.com/okanozdemir/IaC-challenge/blob/main/terraform/variables.tf) and [backend](https://github.com/okanozdemir/IaC-challenge/blob/main/terraform/terraform.tf) bucket. Setup an Rancher 2 server and save the API credentials (URL and Bearer token). Set the environment variables and trigger Github Actions.
