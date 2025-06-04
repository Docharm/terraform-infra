#Replication bucket
resource "aws_s3_bucket" "replication_bucket" {
  provider      = aws.replication
  bucket_prefix = "${regex("[a-z0-9.-]+", lower(var.project_name))}-rpl"
}

# S3 bucket ACL access
resource "aws_s3_bucket_ownership_controls" "replication_bucket_ownership" {
  provider = aws.replication
  bucket   = aws_s3_bucket.replication_bucket.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "replication_bucket_access" {
  provider                = aws.replication
  bucket                  = aws_s3_bucket.replication_bucket.id
  ignore_public_acls      = true
  restrict_public_buckets = true
  block_public_acls       = true
  block_public_policy     = true
}

resource "aws_s3_bucket_acl" "replication_bucket_acl" {
  provider = aws.replication
  bucket   = aws_s3_bucket.replication_bucket.id
  acl      = "private"

  depends_on = [
    aws_s3_bucket_public_access_block.replication_bucket_access,
    aws_s3_bucket_ownership_controls.replication_bucket_ownership
  ]
}

resource "aws_s3_bucket_versioning" "replication_bucket_versioning" {
  provider = aws.replication
  bucket   = aws_s3_bucket.replication_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}


resource "aws_s3_bucket_server_side_encryption_configuration" "replication_bucket_encryption" {
  provider = aws.replication
  bucket   = aws_s3_bucket.replication_bucket.bucket

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.kms_key_arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_logging" "replication_bucket_logging" {
  provider      = aws.replication
  bucket        = aws_s3_bucket.replication_bucket.id
  target_bucket = aws_s3_bucket.replication_bucket.id
  target_prefix = "log/"
}

#Artifact Bucket
resource "aws_s3_bucket" "codepipeline_bucket" {
  bucket_prefix = regex("[a-z0-9.-]+", lower(var.project_name))
  tags          = var.tags
  force_destroy = true
}

# S3 bucket ACL access
resource "aws_s3_bucket_ownership_controls" "codepipeline_bucket_ownership" {
  bucket = aws_s3_bucket.codepipeline_bucket.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}


resource "aws_s3_bucket_public_access_block" "codepipeline_bucket_access" {
  bucket                  = aws_s3_bucket.codepipeline_bucket.id
  ignore_public_acls      = true
  restrict_public_buckets = true
  block_public_acls       = true
  block_public_policy     = true
}

resource "aws_s3_bucket_acl" "codepipeline_bucket_acl" {
  bucket = aws_s3_bucket.codepipeline_bucket.id
  acl    = "private"

  depends_on = [
    aws_s3_bucket_public_access_block.codepipeline_bucket_access,
    aws_s3_bucket_ownership_controls.codepipeline_bucket_ownership
  ]
}

resource "aws_s3_bucket_versioning" "codepipeline_bucket_versioning" {
  bucket = aws_s3_bucket.codepipeline_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "codepipeline_bucket_encryption" {
  bucket = aws_s3_bucket.codepipeline_bucket.bucket

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.kms_key_arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_logging" "codepipeline_bucket_logging" {
  bucket        = aws_s3_bucket.codepipeline_bucket.id
  target_bucket = aws_s3_bucket.codepipeline_bucket.id
  target_prefix = "log/"
}

resource "aws_s3_bucket_replication_configuration" "replication_config" {
  #provider = aws.replication
  # Must have bucket versioning enabled first
  depends_on = [
    aws_s3_bucket_versioning.codepipeline_bucket_versioning,
    aws_s3_bucket_versioning.replication_bucket_versioning
  ]

  role   = aws_iam_role.replication_s3_role.arn
  bucket = aws_s3_bucket.codepipeline_bucket.id

  rule {
    id = "${var.project_name}-replication-rule"

    filter {}

    delete_marker_replication {
      status = "Enabled"
    }

    status = "Enabled"

    destination {
      bucket        = aws_s3_bucket.replication_bucket.arn
      storage_class = "STANDARD"
    }
  }
}