terraform {
  required_version = ">= 1.12.1"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.20.1"
    }
  }

  backend "s3" {
    bucket       = "tf-backend-state-doyeon"
    key          = "env/doyeon/terraform.tfstate"
    region       = "ap-northeast-2"
    use_lockfile = true
    encrypt      = true
  }
}

provider "aws" {
  region = "ap-northeast-2"
}

#Module for creating a new S3 bucket for storing pipeline artifacts
module "s3_artifacts_bucket" {
  source                = "../../modules/storage/s3"
  project_name          = var.project_name
  kms_key_arn           = module.codepipeline_kms.arn
  codepipeline_role_arn = module.codepipeline_iam_role.role_arn

  tags = {
    Project     = var.project_name
    Environment = var.environment
    Account_ID  = local.account_id
    Region      = local.region
  }
}

# Resources

# Module for Infrastructure Source code repository
module "codecommit_infrastructure_source_repo" {
  source = "../../modules/developer_tool/codecommit"

  create_new_repo          = var.create_new_repo
  source_repository_name   = var.source_repo_name
  source_repository_branch = var.source_repo_branch
  repo_approvers_arn       = local.repo_approvers_arn
  kms_key_arn              = module.codepipeline_kms.arn

  tags = {
    Project     = var.project_name
    Environment = var.environment
    Account_ID  = local.account_id
    Region      = local.region
  }
}

# Module for Infrastructure Validation - CodeBuild
module "codebuild_terraform" {
  depends_on = [
    module.codecommit_infrastructure_source_repo
  ]
  source = "../../modules/developer_tool/codebuild"

  project_name                        = var.project_name
  role_arn                            = module.codepipeline_iam_role.role_arn
  s3_bucket_name                      = module.s3_artifacts_bucket.bucket
  build_projects                      = var.build_projects
  build_project_source                = var.build_project_source
  builder_compute_type                = var.builder_compute_type
  builder_image                       = var.builder_image
  builder_image_pull_credentials_type = var.builder_image_pull_credentials_type
  builder_type                        = var.builder_type
  kms_key_arn                         = module.codepipeline_kms.arn

  tags = {
    Project     = var.project_name
    Environment = var.environment
    Account_ID  = local.account_id
    Region      = local.region
  }
}

module "codepipeline_kms" {
  source                = "../../modules/security/kms"
  codepipeline_role_arn = module.codepipeline_iam_role.role_arn

  tags = {
    Project     = var.project_name
    Environment = var.environment
    Account_ID  = local.account_id
    Region      = local.region
  }
}

module "codepipeline_iam_role" {
  source                     = "../../modules/security/iam_role"
  project_name               = var.project_name
  create_new_role            = var.create_new_role
  codepipeline_iam_role_name = var.create_new_role == true ? "${var.project_name}-codepipeline-role" : var.codepipeline_iam_role_name
  source_repository_name     = var.source_repo_name
  kms_key_arn                = module.codepipeline_kms.arn
  s3_bucket_arn              = module.s3_artifacts_bucket.arn

  tags = {
    Project     = var.project_name
    Environment = var.environment
    Account_ID  = local.account_id
    Region      = local.region
  }
}

# Module for Infrastructure Validate, Plan, Apply and Destroy - CodePipeline
module "codepipeline_terraform" {
  depends_on = [
    module.codebuild_terraform,
    module.s3_artifacts_bucket
  ]
  source = "../../modules/developer_tool/codepipeline"

  project_name          = var.project_name
  source_repo_name      = var.source_repo_name
  source_repo_branch    = var.source_repo_branch
  s3_bucket_name        = module.s3_artifacts_bucket.bucket
  codepipeline_role_arn = module.codepipeline_iam_role.role_arn
  stages                = var.stage_input
  kms_key_arn           = module.codepipeline_kms.arn
  aws_region            = local.region
  s3_tfstate_bucket     = var.s3_tfstate_bucket_name


  tags = {
    Project     = var.project_name
    Environment = var.environment
    Account_ID  = local.account_id
    Region      = local.region
  }
}

# network 구성
module "network" {
  source                  = "../../modules/network"
  project_name            = var.project_name
  vpc_cidr                = var.vpc_cidr
  public_subnet_cidr      = var.public_subnet_cidr
  private_subnet_cidr     = var.private_subnet_cidr
  public_az               = var.public_az
  private_az              = var.private_az
  public_route_table_name = var.public_route_table_name
  #ami = data.aws_ami.ubuntu.id
  ec2_key_name = var.ec2_key_name
}
