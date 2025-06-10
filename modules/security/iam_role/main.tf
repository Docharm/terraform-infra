resource "aws_iam_role" "codepipeline_role" {
  count              = var.create_new_role ? 1 : 0
  name               = var.codepipeline_iam_role_name
  tags               = var.tags
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "codepipeline.amazonaws.com"
      },
      "Effect": "Allow"
    },
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
  path               = "/"
}

# TO-DO : replace all * with resource names / arn
resource "aws_iam_policy" "codepipeline_policy" {
  count       = var.create_new_role ? 1 : 0
  name        = "${var.project_name}-codepipeline-policy"
  description = "Policy to allow codepipeline to execute"
  tags        = var.tags
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect":"Allow",
      "Action": [
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:PutObjectAcl",
        "s3:PutObject"
      ],
      "Resource": "${var.s3_bucket_arn}/*"
    },
    {
      "Effect":"Allow",
      "Action": [
        "s3:GetBucketVersioning"
      ],
      "Resource": "${var.s3_bucket_arn}"
    },
    {
      "Effect": "Allow",
      "Action": [
         "kms:DescribeKey",
         "kms:GenerateDataKey*",
         "kms:Encrypt",
         "kms:ReEncrypt*",
         "kms:Decrypt"
      ],
      "Resource": "${var.kms_key_arn}"
    },
    {
      "Effect": "Allow",
      "Action": [
         "codecommit:GitPull",
         "codecommit:GitPush",
         "codecommit:GetBranch",
         "codecommit:CreateCommit",
         "codecommit:ListRepositories",
         "codecommit:BatchGetCommits",
         "codecommit:BatchGetRepositories",
         "codecommit:GetCommit",
         "codecommit:GetRepository",
         "codecommit:GetUploadArchiveStatus",
         "codecommit:ListBranches",
         "codecommit:UploadArchive"
      ],
      "Resource": "arn:aws:codecommit:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:${var.source_repository_name}"
    },
    {
      "Effect": "Allow",
      "Action": [
        "codebuild:BatchGetBuilds",
        "codebuild:StartBuild",
        "codebuild:BatchGetProjects"
      ],
      "Resource": "arn:aws:codebuild:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:project/${var.project_name}*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "codebuild:CreateReportGroup",
        "codebuild:CreateReport",
        "codebuild:UpdateReport",
        "codebuild:BatchPutTestCases"
      ],
      "Resource": "arn:aws:codebuild:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:report-group/${var.project_name}*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:${data.aws_partition.current.partition}:logs:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:log-group:*"
    },
    { 
      "Effect": "Allow",
      "Action": [
          "ec2:DescribeVpcs",
          "ec2:DescribeSubnets",
          "ec2:DescribeRouteTables",
          "ec2:DescribeInternetGateways",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeNatGateways",
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeVpcAttribute",
          "ec2:DescribeInstanceTypes" 
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

# 도연iamrole 추가 
resource "aws_iam_policy" "describe_ami" { #AMI 조회 권한 부여 - 최신 AMI 자동 
  name        = "${var.project_name}-describe-ami"
  description = "Allow DescribeImages to look up AMIs"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["ec2:DescribeImages"],
        Resource = "*"
      }
    ]
  })
}
resource "aws_iam_policy" "read_permissions" { 
  name        = "${var.project_name}-read-ec2-iam"
  description = "Allow EC2/IAM read operations for CodeBuild"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "ec2:DescribeInstances",
          "ec2:DescribeImages",
          "iam:GetPolicy"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "read_permissions_attach" {
  role       = aws_iam_role.codepipeline_role[0].name
  policy_arn = aws_iam_policy.read_permissions.arn
}
resource "aws_iam_role_policy_attachment" "attach_describe_ami" {
  role = aws_iam_role.codepipeline_role[0].name
  policy_arn = aws_iam_policy.describe_ami.arn
}

resource "aws_iam_role_policy_attachment" "codepipeline_role_attach" {
  count      = var.create_new_role ? 1 : 0
  role       = aws_iam_role.codepipeline_role[0].name
  policy_arn = aws_iam_policy.codepipeline_policy[0].arn
}
resource "aws_iam_policy" "codepipeline_get_policy_versions" {
  name        = "infra-doyeon-get-policy-version"
  description = "Allow CodePipeline to get IAM policy versions"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["iam:GetPolicy", "iam:GetPolicyVersion"]
        Resource = [
          "arn:aws:iam::866874933972:policy/infra-doyeon-describe-ami",
          "arn:aws:iam::866874933972:policy/infra-doyeon-read-ec2-iam"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_get_policy_version" {
  role       = aws_iam_role.codepipeline_role[0].name
  policy_arn = aws_iam_policy.codepipeline_get_policy_versions.arn
}

resource "aws_iam_role_policy" "codecommit_inline_update_default_branch" { # 기본 브랜치 업데이트 
  count = var.create_new_role ? 1 : 0

  name = "AllowUpdateDefaultBranch"
  role = aws_iam_role.codepipeline_role[0].name

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "codecommit:UpdateDefaultBranch"
        ],
        Resource = "arn:aws:codecommit:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:${var.source_repository_name}"
      }
    ]
  })
}


