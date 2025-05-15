resource "kubernetes_manifest" "graviton_nodeclass" {

  provider = kubernetes

  manifest = {
    apiVersion = "karpenter.k8s.aws/v1"
    kind       = "EC2NodeClass"
    metadata = {
      name = "graviton-nodeclass"
    }
    spec = {
      subnetSelectorTerms = [{
        tags = {
          "karpenter.sh/discovery" = module.eks.cluster_name
        }
      }]
      securityGroupSelectorTerms = [{
        tags = {
          "karpenter.sh/discovery" = module.eks.cluster_name
        }
      }]
      amiFamily = "AL2023"
      role      = module.karpenter.node_iam_role_name
      tags = {
        Name                     = "graviton-karpenter"
        "karpenter.sh/discovery" = module.eks.cluster_name
      }
    }
  }
}

resource "kubernetes_manifest" "amd64-nodeclass" {

  provider = kubernetes

  manifest = {
    apiVersion = "karpenter.k8s.aws/v1"
    kind       = "EC2NodeClass"
    metadata = {
      name = "amd64-nodeclass"
    }
    spec = {
      subnetSelectorTerms = [{
        tags = {
          "karpenter.sh/discovery" = module.eks.cluster_name
        }
      }]
      securityGroupSelectorTerms = [{
        tags = {
          "karpenter.sh/discovery" = module.eks.cluster_name
        }
      }]
      amiFamily = "AL2023"
      role      = module.karpenter.node_iam_role_name
      tags = {
        Name                     = "amd64-karpenter"
        "karpenter.sh/discovery" = module.eks.cluster_name
      }
    }
  }
}
resource "kubernetes_manifest" "graviton_nodepool" {

  provider = kubernetes

  manifest = {
    apiVersion = "karpenter.sh/v1"
    kind       = "NodePool"
    metadata = {
      name = "graviton-nodepool"
    }
    spec = {
      template = {
        spec = {
          nodeClassRef = {
            name  = "graviton-nodeclass"
            group = "karpenter.k8s.aws"
            kind  = "EC2NodeClass"
          }
          requirements = [
            {
              key      = "kubernetes.io/arch"
              operator = "In"
              values   = ["arm64"]
            },
            {
              key      = "karpenter.k8s.aws/capacity-type"
              operator = "In"
              values   = ["SPOT", "ON_DEMAND"]
            },
            {
              key      = "node.kubernetes.io/instance-type"
              operator = "In"
              values   = ["c7g.large", "c7g.xlarge", "c7g.2xlarge", "m7g.large", "m7g.xlarge", "m7g.2xlarge"]
            }
          ]
        }
      }
      limits = {
        cpu = "1000"
      }
      disruption = {
        consolidationPolicy = "WhenEmpty"
      }
    }
  }
}

resource "kubernetes_manifest" "amd64_nodepool" {

  provider = kubernetes

  manifest = {
    apiVersion = "karpenter.sh/v1"
    kind       = "NodePool"
    metadata = {
      name = "amd64-nodepool"
    }
    spec = {
      template = {
        spec = {
          nodeClassRef = {
            name  = "amd64-nodeclass"
            group = "karpenter.k8s.aws"
            kind  = "EC2NodeClass"
          }
          requirements = [
            {
              key      = "kubernetes.io/arch"
              operator = "In"
              values   = ["amd64"]
            },
            {
              key      = "karpenter.k8s.aws/capacity-type"
              operator = "In"
              values   = ["SPOT", "ON_DEMAND"]
            },
            {
              key      = "node.kubernetes.io/instance-type"
              operator = "In"
              values   = ["c5.large", "c5.xlarge", "c5.2xlarge", "m5.large", "m5.xlarge", "m5.2xlarge", "r5.large", "r5.xlarge", "r5.2xlarge"]
            }
          ]
        }
      }
      limits = {
        cpu = "2000"
      }
      disruption = {
        consolidationPolicy = "WhenEmpty"
      }
    }
  }
}
