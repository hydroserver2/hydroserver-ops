# Creation of S3 bucket for TimescaleDB backup
resource "aws_s3_bucket" "timescale_backup_bucket" {
  bucket = "timescale-backup-${var.instance}-${data.aws_caller_identity.current.account_id}"
}


# ------------------------------------------------ #
# S3 Restrict Public Access                        #
# ------------------------------------------------ #
resource "aws_s3_bucket_public_access_block" "timescale_backup_bucket" {
  bucket = aws_s3_bucket.timescale_backup_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ------------------------------------------------ #
# S3 Ownership Controls                            #
# ------------------------------------------------ #
resource "aws_s3_bucket_ownership_controls" "timescale_backup_bucket" {
  bucket = aws_s3_bucket.timescale_backup_bucket.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
  depends_on = [aws_s3_bucket_public_access_block.timescale_backup_bucket]
}


