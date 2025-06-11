terraform {
  backend "s3" {
    bucket = "tf-backend-state-doyeon"
    key    = "env/doyeon/terraform.tfstate"
    region = "ap-northeast-2"
  }
}