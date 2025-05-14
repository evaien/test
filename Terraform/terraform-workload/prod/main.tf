module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "5.1.2"

  name            = var.vpc_name
  cidr            = var.vpc_cidr
  azs             = var.azs
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  enable_nat_gateway = true
  one_nat_gateway_per_az = true
  single_nat_gateway = false

  tags = local.common_tags
}

module "eks" {
  source = "terraform-aws-modules/eks/aws"
  version = "20.8.4"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  enable_irsa = true
  eks_managed_node_groups = var.node_group_config
  cluster_addons          = var.cluster_addons

  tags = local.common_tags
}

module "karpenter" {
  source = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "20.8.4"

  cluster_name                   = module.eks.cluster_name
  cluster_endpoint               = module.eks.cluster_endpoint
  cluster_certificate_authority_data = module.eks.cluster_certificate_authority_data

  irsa_oidc_provider_arn        = module.eks.oidc_provider_arn
  irsa_namespace                = "kube-system"
  irsa_service_account_name     = "karpenter"

  create_iam_role               = true
  iam_role_name                 = "${local.cluster_name}-karpenter"
  iam_role_additional_policies = [
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    "arn:aws:iam::aws:policy/AmazonEC2FullAccess",
  ]

  settings = {
    clusterName         = module.eks.cluster_name
    clusterEndpoint     = module.eks.cluster_endpoint
    defaultInstanceProfile = module.eks.node_group_iam_instance_profile_name
  }

  tags = local.common_tags
}