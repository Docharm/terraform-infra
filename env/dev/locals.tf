locals {
  account_id  = data.aws_caller_identity.current.account_id
  region      = data.aws_region.current.name
  owner       = regex("([^/]+)$", data.aws_caller_identity.current.arn)[0]
  
  repo_approvers_arn = "arn:aws:iam::${local.account_id}:role/${var.repo_approvers_role}/*"
}