data "aws_eks_cluster_auth" "this" {
  name     = module.eks.cluster_name
  provider = aws
}

data "aws_ecrpublic_authorization_token" "token" {
  provider = aws.virginia
}