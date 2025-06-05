locals {
  codepipeline_role_name = split("/", var.codepipeline_role_arn)[1]
}

resource "aws_iam_role_policy" "allow_terraform_full_access" {
  name = "TerraformFullAccess"

  role = local.codepipeline_role_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowTerraformS3BackendAccess"
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = [
          "arn:aws:s3:::${var.s3_tfstate_bucket}",
          "arn:aws:s3:::${var.s3_tfstate_bucket}/*"
        ]
      },
      {
        Sid    = "AllowTerraformIAMManagement"
        Effect = "Allow"
        Action = [
          "iam:GetRole",
          "iam:CreateRole",
          "iam:DeleteRole",
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy",
          "iam:GetPolicy",
          "iam:CreatePolicy",
          "iam:DeletePolicy",
          "iam:ListRoles",
          "iam:ListPolicies",
          "iam:ListRolePolicies",
          "iam:GetRolePolicy",
          "iam:GetPolicyVersion",
          "iam:ListAttachedRolePolicies",
          "iam:TagRole"
        ]
        Resource = [
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.project_name}-codepipeline-role",
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.project_name}-replication-role",
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/${var.project_name}-replication-policy",
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/${var.project_name}-codepipeline-policy"
        ]
      },
      {
        Sid    = "AllowTerraformCodePipelineRead"
        Effect = "Allow"
        Action = [
          "codepipeline:GetPipeline",
          "codepipeline:GetPipelineState",
          "codepipeline:ListPipelines",
          "codepipeline:ListTagsForResource"
        ]
        Resource = [
          "arn:aws:codepipeline:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:${var.project_name}-pipeline"
        ]
      },
      {
        Sid    = "AllowTerraformS3BucketTagging"
        Effect = "Allow"
        Action = [
          "s3:PutBucketTagging"
        ]
        Resource = [
          "arn:aws:s3:::${var.project_name}*"
        ]
      }
    ]
  })
}