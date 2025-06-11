# CodePipeline과 CodeBuild가 사용할 IAM Role
resource "aws_iam_role" "codepipeline_role" {
  count              = var.create_new_role ? 1 : 0
  name               = var.codepipeline_iam_role_name
  tags               = var.tags
  path               = "/"
  # CodePipeline과 CodeBuild에서 사용할 수 있도록 trust relationship 설정
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = ["codepipeline.amazonaws.com", "codebuild.amazonaws.com"]
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# CodePipeline 실행을 위한 기본 정책
resource "aws_iam_policy" "codepipeline_policy" {
  count       = var.create_new_role ? 1 : 0
  name        = "${var.project_name}-codepipeline-policy"
  description = "Allow CodePipeline to access core AWS resources"
  tags        = var.tags
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
      # S3 접근 권한
      {
        Effect = "Allow",
        Action = ["s3:GetObject", "s3:GetObjectVersion", "s3:PutObjectAcl", "s3:PutObject"],
        Resource = "${var.s3_bucket_arn}/*"
      },
      {
        Effect = "Allow",
        Action = ["s3:GetBucketVersioning"],
        Resource = "${var.s3_bucket_arn}"
      },
      # KMS 권한
      {
        Effect = "Allow",
        Action = ["kms:DescribeKey", "kms:GenerateDataKey*", "kms:Encrypt", "kms:ReEncrypt*", "kms:Decrypt"],
        Resource = "${var.kms_key_arn}"
      },
      # CodeCommit 권한
      {
        Effect = "Allow",
        Action = [
          "codecommit:GitPull", "codecommit:GitPush", "codecommit:GetBranch",
          "codecommit:CreateCommit", "codecommit:ListRepositories", "codecommit:BatchGetCommits",
          "codecommit:BatchGetRepositories", "codecommit:GetCommit", "codecommit:GetRepository",
          "codecommit:GetUploadArchiveStatus", "codecommit:ListBranches", "codecommit:UploadArchive"
        ],
        Resource = "arn:aws:codecommit:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:${var.source_repository_name}"
      },
      # CodeBuild 권한
      {
        Effect = "Allow",
        Action = ["codebuild:BatchGetBuilds", "codebuild:StartBuild", "codebuild:BatchGetProjects"],
        Resource = "arn:aws:codebuild:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:project/${var.project_name}*"
      },
      {
        Effect = "Allow",
        Action = ["codebuild:CreateReportGroup", "codebuild:CreateReport", "codebuild:UpdateReport", "codebuild:BatchPutTestCases"],
        Resource = "arn:aws:codebuild:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:report-group/${var.project_name}*"
      },
      # 로그 그룹 생성 권한
      {
        Effect = "Allow",
        Action = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"],
        Resource = "arn:${data.aws_partition.current.partition}:logs:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:log-group:*"
      },
      # VPC 리소스 조회 권한 (보통 VPC 설정 시 필요)
      {
        Effect = "Allow",
        Action = [
          "ec2:DescribeVpcs", "ec2:DescribeSubnets", "ec2:DescribeRouteTables", "ec2:DescribeInternetGateways",
          "ec2:DescribeSecurityGroups", "ec2:DescribeNatGateways", "ec2:DescribeAvailabilityZones",
          "ec2:DescribeVpcAttribute", "ec2:DescribeInstanceTypes", "ec2:DescribeInstances", "ec2:DescribeImages"
        ],
        Resource = "*"
      },
      # CodePipeline 자체 조회 권한
      {
        Effect = "Allow",
        Action = ["codepipeline:GetPipeline"],
        Resource = "arn:aws:codepipeline:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:${var.project_name}"
      },
      # IAM 정책 조회 권한
      {
        Effect = "Allow",
        Action = ["iam:GetPolicy", "iam:GetPolicyVersion"],
        Resource = [
          "arn:aws:iam::866874933972:policy/infra-doyeon-describe-ami",
          "arn:aws:iam::866874933972:policy/infra-doyeon-read-ec2-iam"
        ]
      }
    ]
  })
}

# CodeCommit 기본 브랜치 업데이트 허용
resource "aws_iam_policy" "codepipeline_inline_update_branch" {
  count = var.create_new_role ? 1 : 0
  name  = "${var.project_name}-update-default-branch"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = ["codecommit:UpdateDefaultBranch"],
        Resource = "arn:aws:codecommit:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:${var.source_repository_name}"
      }
    ]
  })
}

# AMI 조회 권한 (예: 최신 Amazon Linux 2 AMI 등)
resource "aws_iam_policy" "describe_ami" {
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

# EC2와 IAM 정보 조회 권한 (추가적인 권한이 필요한 경우)
resource "aws_iam_policy" "read_permissions" {
  name        = "${var.project_name}-read-ec2-iam"
  description = "Allow EC2/IAM read operations for CodeBuild"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = ["ec2:DescribeInstances", "ec2:DescribeImages", "iam:GetPolicy"],
        Resource = "*"
      }
    ]
  })
}

# 정책을 IAM Role에 연결
resource "aws_iam_role_policy_attachment" "attach_codepipeline_policy" {
  count      = var.create_new_role ? 1 : 0
  role       = aws_iam_role.codepipeline_role[0].name
  policy_arn = aws_iam_policy.codepipeline_policy[0].arn
}

resource "aws_iam_role_policy_attachment" "attach_update_branch" {
  count      = var.create_new_role ? 1 : 0
  role       = aws_iam_role.codepipeline_role[0].name
  policy_arn = aws_iam_policy.codepipeline_inline_update_branch[0].arn
}

resource "aws_iam_role_policy_attachment" "attach_describe_ami" {
  role       = aws_iam_role.codepipeline_role[0].name
  policy_arn = aws_iam_policy.describe_ami.arn
}

resource "aws_iam_role_policy_attachment" "read_permissions_attach" {
  role       = aws_iam_role.codepipeline_role[0].name
  policy_arn = aws_iam_policy.read_permissions.arn
}
