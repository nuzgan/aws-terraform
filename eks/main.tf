provider "aws" {
  profile = "personalAccount"
}

module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "~> 20.0"
  cluster_name    = "bottlerocket-cluster"
  cluster_version = "1.29"
  cluster_endpoint_public_access = true
  subnet_ids      = ["subnet-0aaa11003ca8a3333", "subnet-0c8f166169b33ea0b", "subnet-08be347967a5f63e2"] # Replace with your subnet IDs
  vpc_id          = "vpc-0ff8d89a26da9c54e"                                                              # Replace with your vpc IDs

  eks_managed_node_groups = {
    eks_nodes = {
      min_size     = 1
      max_size     = 3
      desired_size = 2

      instance_types    = ["t2.micro"]
      ami_type          = "BOTTLEROCKET_x86_64"

    }
  }

  # To add the current caller identity as an administrator
  enable_cluster_creator_admin_permissions = true

  tags = {
    Environment = "staging"
    Terraform   = "true"
  }
}
