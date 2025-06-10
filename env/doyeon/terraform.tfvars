# Project Configuration
project_name = "infra-doyeon"
environment  = "doyeon"

# CodeCommit / CodePipeline Configuration
source_repo_name   = "infra-doyeon"
source_repo_branch = "develop"
create_new_repo    = false

# IAM Configuration
repo_approvers_role = "CodeCommitReview"
create_new_role     = true
#codepipeline_iam_role_name = "doyeon-pipeline-role"

# CodeBuild Steps Configuration
stage_input = [
  { name = "validate", category = "Test", owner = "AWS", provider = "CodeBuild", input_artifacts = "SourceOutput", output_artifacts = "ValidateOutput" },
  { name = "plan", category = "Test", owner = "AWS", provider = "CodeBuild", input_artifacts = "ValidateOutput", output_artifacts = "PlanOutput" },
  { name = "apply", category = "Build", owner = "AWS", provider = "CodeBuild", input_artifacts = "PlanOutput", output_artifacts = "ApplyOutput" },
  { name = "destroy", category = "Build", owner = "AWS", provider = "CodeBuild", input_artifacts = "ApplyOutput", output_artifacts = "DestroyOutput" }
]

build_projects = ["validate", "plan", "apply", "destroy"]

s3_tfstate_bucket_name = "tf-backend-state-doyeon"

tags = {
  Project = "infra-doyeon"
  Owner   = "doyeon"
  Env     = "dev"
}

vpc_cidr                = "10.0.0.0/16"
public_subnet_cidr      = "10.0.1.0/24"
private_subnet_cidr     = "10.0.2.0/24"
public_az               = "ap-northeast-2a"
private_az              = "ap-northeast-2c"
public_route_table_name = "doyeon-public-rt-main"
ec2_instance_type       = "t3.micro"
ec2_key_name            = "doyeon-key" # 도연님이 콘솔에서 만든 키페어 이름