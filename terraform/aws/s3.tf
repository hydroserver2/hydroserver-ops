# ---------------------------------
# AWS S3 Static Bucket
# ---------------------------------

resource "aws_s3_bucket" "static_bucket" {
  bucket = "hydroserver-static-${var.instance}-${data.aws_caller_identity.current.account_id}"

  tags = {
    "${var.tag_key}" = local.tag_value
  }
}

resource "aws_s3_bucket_public_access_block" "static_bucket" {
  bucket = aws_s3_bucket.static_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "static_bucket" {
  bucket = aws_s3_bucket.static_bucket.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
  depends_on = [aws_s3_bucket_public_access_block.static_bucket]
}

resource "aws_s3_object" "static_folder" {
  bucket = aws_s3_bucket.static_bucket.id
  key    = "static/"
}


# ---------------------------------
# AWS S3 Media Bucket
# ---------------------------------

resource "aws_s3_bucket" "media_bucket" {
  bucket = "hydroserver-media-${var.instance}-${data.aws_caller_identity.current.account_id}"

  tags = {
    "${var.tag_key}" = local.tag_value
  }
}

resource "aws_s3_bucket_public_access_block" "media_bucket" {
  bucket = aws_s3_bucket.media_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "media_bucket" {
  bucket = aws_s3_bucket.media_bucket.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
  depends_on = [aws_s3_bucket_public_access_block.media_bucket]
}

resource "aws_s3_object" "media_folder" {
  bucket = aws_s3_bucket.media_bucket.id
  key    = "media/"
}
