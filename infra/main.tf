module "vpc" {
  source = "./modules/vpc"
}

module "eks" {
  source = "./modules/eks"
  vpc_id     = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  vpc_cidr  = module.vpc.vpc_cidr
}

module "pod" {
  source = "./modules/pod"
  eks_cluster_name = module.eks.cluster_name
}