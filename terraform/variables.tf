# Input variables

# Node image
variable "image" { 
	default = "ami-024e928dca73bfe66"
}

# Node disk size in GB
variable "disksize" {
	default = 32
}

# Node type
variable "type" {
	default = "m5.large"
}

# Kubernetes version
variable "k8version" {
	default = "v1.21.5-rancher1-1"
}

# Docker version
variable "dockerurl" {
	default = "https://releases.rancher.com/install-docker/19.03.sh"
}

# Number of nodes
variable "numnodes" {
	default = 2
}

# Monitoring chart
variable "monchart" {
	default = "100.0.0"
}

# Logging chart
variable "logchart" {
	default = "100.0.0"
}

# EC2 Availability Zone
variable "ec2-zone" {
	default = "a"
}

# EC2 Subnet
variable "ec2-subnet" {
	default = "subnet-5c305236"
}

# EC2 VPC
variable "ec2-vpc" {
	default = "vpc-2b813a41"
}

# EC2 Security Group
variable "ec2-secgroup" {
	default = "rancher-nodes"
}

# Hack: Time to wait for Kubernetes to deploy
variable "delaysec" {
	default = 600
}

# Prometheus username
variable "prom_remote_user" {
        default = "ooz"
}

# Prometheus password
variable "prom_remote_pass" {
        default = "ooz"
}

variable "AWS_REGION" { }

variable "ECR_NAME" { }

variable "RANCHER_URL" { }

variable "RANCHER_TOKEN" { }

variable "AWS_ACCESS_KEY_ID" { }

variable "AWS_SECRET_ACCESS_KEY" { }
