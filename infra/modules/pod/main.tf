module "external_dns_pod_identity" {
  source = "terraform-aws-modules/eks-pod-identity/aws"

  name = "external-dns"

  attach_external_dns_policy    = true
  external_dns_hosted_zone_arns = ["arn:aws:route53:::hostedzone/IClearlyMadeThisUp"]

  associations = {
    this = {
      cluster_name    = var.eks_cluster_name
      namespace       = "external-dns"
      service_account = "external-dns-sa"
    }
  }

}