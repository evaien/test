vpc_name        = "prod-vpc"
vpc_cidr        = "10.0.0.0/16"
azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
private_subnets = ["10.0.1.0/22", "10.0.5.0/22", "10.0.9.0/22"]
public_subnets = ["10.0.13.0/24", "10.0.14.0/24", "10.0.15.0/24"]
cluster_name    = "prod-cluster"
cluster_version = "1.29"
tags = {
      "Environment" = "production"
      "Project"     = "innovate"
}
node_group_config = {
    system-pool = {
      desired_size = 3
      min_size     = 3
      max_size     = 6

      instance_types = ["m5.xlarge"]
      ami_type       = "AL2023_x86_64_STANDARD"

      taints = [
        {
          key    = "CriticalAddonsOnly"
          value  = "true"
          effect = "NO_SCHEDULE"
        }
      ]

      labels = {
        role = "system"
      }

      tags = {
        Name = "eks-system-nodes"
      }
    }
}
cluster_addons = {
  coredns = {}
  vpc-cni = {}
  kube-proxy = {}
}