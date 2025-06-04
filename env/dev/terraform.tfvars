# Project Configuration
project_name        = "cloocus-tf-project"
environment         = "dev"

# CodeCommit / CodePipeline Configuration
source_repo_name    = "infra"
source_repo_branch  = "develop"
create_new_repo     = false

# IAM Configuration
repo_approvers_role = "CodeCommitReview"
create_new_role     = true

# CodeBuild Steps Configuration
stage_input = [
  { name = "validate", category = "Test", owner = "AWS", provider = "CodeBuild", input_artifacts = "SourceOutput", output_artifacts = "ValidateOutput" },
  { name = "plan", category = "Test", owner = "AWS", provider = "CodeBuild", input_artifacts = "ValidateOutput", output_artifacts = "PlanOutput" },
  { name = "apply", category = "Build", owner = "AWS", provider = "CodeBuild", input_artifacts = "PlanOutput", output_artifacts = "ApplyOutput" },
  { name = "destroy", category = "Build", owner = "AWS", provider = "CodeBuild", input_artifacts = "ApplyOutput", output_artifacts = "DestroyOutput" }
]

build_projects = ["validate", "plan", "apply", "destroy"]