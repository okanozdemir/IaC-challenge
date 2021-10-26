# Terraform resources 

# Random ID
resource "random_id" "instance_id" {
 byte_length = 3
}

# IAM
resource "aws_iam_role" "rancher_role" {
  name               = "rancher-combined-control-worker"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "rancher-combined-control-worker" {
  name = "rancher-combined-control-worker"
  role = aws_iam_role.rancher_role.name
}

resource "aws_iam_policy" "rancher_policy" {
  name        = "rancher-combined-control-worker"
  description = "Policy for Rancher"
  policy = file("${path.module}/json/combined-control-worker.json")
}

resource "aws_iam_role_policy_attachment" "policy-attach" {
  role       = aws_iam_role.rancher_role.name
  policy_arn = aws_iam_policy.rancher_policy.arn
}

# ECR
module "ecr-repository" {
  name   = var.ECR_NAME
  source = "QuiNovas/ecr/aws"
  version = "3.0.2"
}

# Rancher cloud credentials
resource "rancher2_cloud_credential" "credential_ec2" {
  name = "EC2 Credentials"
  amazonec2_credential_config {
    access_key = var.AWS_ACCESS_KEY_ID
    secret_key = var.AWS_SECRET_ACCESS_KEY
  }
}

# Rancher node template
resource "rancher2_node_template" "template_ec2" {
  name = "EC2 Node Template"
  cloud_credential_id = rancher2_cloud_credential.credential_ec2.id
  engine_install_url = var.dockerurl
  amazonec2_config {
    ami = var.image
    region = var.AWS_REGION
    security_group = [var.ec2-secgroup]
    subnet_id = var.ec2-subnet
    vpc_id = var.ec2-vpc
    zone = var.ec2-zone
    root_size = var.disksize
    instance_type = var.type
    iam_instance_profile = "rancher-combined-control-worker"
    tags = "kubernetes.io/cluster/rancher,owned"
  }

  depends_on = [rancher2_cloud_credential.credential_ec2]
}

# Rancher cluster
resource "rancher2_cluster" "cluster_ec2" {
  name         = "ec2-${random_id.instance_id.hex}"
  description  = "Terraform"

  rke_config {
    kubernetes_version = var.k8version
    cloud_provider {
      name = "aws"
      aws_cloud_provider {
        global {
          kubernetes_cluster_tag = "rancher"
        }
      }
    }
    ignore_docker_version = false
    network {
      plugin = "flannel"
    }
    services {
      etcd {
        backup_config {
          enabled = false
        }
      }
      kubelet {
        extra_args  = {
          max_pods = 70
        }
      }
    }
  }

  depends_on = [rancher2_node_template.template_ec2]
}

# Rancher node pool
resource "rancher2_node_pool" "nodepool_ec2" {
  cluster_id = rancher2_cluster.cluster_ec2.id
  name = "nodepool"
  hostname_prefix = "rke-${random_id.instance_id.hex}-"
  node_template_id = rancher2_node_template.template_ec2.id
  quantity = var.numnodes
  control_plane = true
  etcd = true
  worker = true

  depends_on = [rancher2_node_template.template_ec2]
}

# Delay hack part 1
resource "null_resource" "before" {
  depends_on = [rancher2_cluster.cluster_ec2,rancher2_node_pool.nodepool_ec2]
}

# Delay hack part 2
resource "null_resource" "delay" {
  provisioner "local-exec" {
    command = "sleep ${var.delaysec}"
  }

  triggers = {
    "before" = "null_resource.before.id"
  }
}

# Kubeconfig file
resource "local_file" "kubeconfig" {
  filename = "${path.module}/.kube/config"
  content = rancher2_cluster.cluster_ec2.kube_config
  file_permission = "0600"

  depends_on = [null_resource.delay]
}

# Cluster logging CRD
resource "rancher2_app_v2" "syslog_crd_ec2" {
  lifecycle {
    ignore_changes = all
  }
  cluster_id = rancher2_cluster.cluster_ec2.id
  name = "rancher-logging-crd"
  namespace = "cattle-logging-system"
  repo_name = "rancher-charts"
  chart_name = "rancher-logging-crd"
  chart_version = var.logchart

  depends_on = [local_file.kubeconfig,rancher2_cluster.cluster_ec2,rancher2_node_pool.nodepool_ec2]
}

# Cluster logging
resource "rancher2_app_v2" "syslog_ec2" {
  lifecycle {
    ignore_changes = all
  }
  cluster_id = rancher2_cluster.cluster_ec2.id
  name = "rancher-logging"
  namespace = "cattle-logging-system"
  repo_name = "rancher-charts"
  chart_name = "rancher-logging"
  chart_version = var.logchart

  depends_on = [rancher2_app_v2.syslog_crd_ec2,rancher2_cluster.cluster_ec2,rancher2_node_pool.nodepool_ec2]
}

# Monitoring namespace
resource "rancher2_namespace" "promns_ec2" {
  lifecycle {
    ignore_changes = all
  }
  name = "cattle-monitoring-system"
  project_id = data.rancher2_project.system.id
  description = "Terraform"

  depends_on = [rancher2_app_v2.syslog_ec2,rancher2_cluster.cluster_ec2,rancher2_node_pool.nodepool_ec2]
}

# Prometheus secret
resource "rancher2_secret_v2" "promsecret_ec2" {
  lifecycle {
    ignore_changes = all
  }
  cluster_id = rancher2_cluster.cluster_ec2.id
  name = "remote-writer"
  namespace = "cattle-monitoring-system"
  type = "kubernetes.io/basic-auth"
  data = {
    username = var.prom_remote_user
    password = var.prom_remote_pass
  }

  depends_on = [rancher2_namespace.promns_ec2,rancher2_cluster.cluster_ec2,rancher2_node_pool.nodepool_ec2]
}

# Cluster monitoring
resource "rancher2_app_v2" "monitor_ec2" {
  lifecycle {
    ignore_changes = all
  }
  cluster_id = rancher2_cluster.cluster_ec2.id
  name = "rancher-monitoring"
  namespace = "cattle-monitoring-system"
  repo_name = "rancher-charts"
  chart_name = "rancher-monitoring"
  chart_version = var.monchart
  values = templatefile("${path.module}/files/values.yaml", {})

  depends_on = [rancher2_secret_v2.promsecret_ec2,rancher2_cluster.cluster_ec2,rancher2_node_pool.nodepool_ec2]
}

