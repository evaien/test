locals {
  common_tags = merge(
    {
      "Terraform" = "true"
      "Owner"     = "somebody"
    },
    var.tags
  )
}
