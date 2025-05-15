module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.21.0"

  name            = var.vpc_name
  cidr            = var.vpc_cidr
  azs             = var.azs
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  enable_nat_gateway     = true
  one_nat_gateway_per_az = true
  single_nat_gateway     = false

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
    "karpenter.sh/discovery" = var.cluster_name
  }

  tags = local.common_tags
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.36.0"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  enable_cluster_creator_admin_permissions = true
  cluster_endpoint_public_access           = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  enable_irsa             = true
  eks_managed_node_groups = var.node_group_config
  cluster_addons          = var.cluster_addons


  node_security_group_tags = merge(local.common_tags, {
    "karpenter.sh/discovery" = var.cluster_name
  })

  tags = local.common_tags
}

module "karpenter" {
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "20.36.0"

  cluster_name = module.eks.cluster_name

  enable_irsa            = true
  irsa_oidc_provider_arn = module.eks.oidc_provider_arn

  node_iam_role_use_name_prefix = false
  node_iam_role_name            = "karpenter-role"

  node_iam_role_additional_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }

  enable_v1_permissions = true

  tags = local.common_tags
}

resource "helm_release" "karpenter" {
  provider   = helm
  name       = "karpenter"
  namespace  = "kube-system"
  repository = "https://charts.karpenter.sh"
  chart      = "karpenter"
  version    = "1.4.0"

  set = [
    {
      name  = "settings.clusterName"
      value = module.eks.cluster_name
    },
    {
      name  = "settings.clusterEndpoint"
      value = module.eks.cluster_endpoint
    },
    {
      name  = "settings.interruptionQueue"
      value = module.karpenter.queue_name
    },
    {
      name  = "webhook.enabled"
      value = "false"
    },
    {
      name  = "nodeSelector.karpenter\\.sh/controller"
      value = "true"
    },
    {
      name  = "dnsPolicy"
      value = "Default"
    }
  ]

}