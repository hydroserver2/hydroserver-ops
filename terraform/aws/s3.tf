# ------------------------------------------------ #
# HydroServer S3 Buckets                           #
# ------------------------------------------------ #

resource "aws_s3_bucket" "hydroserver_data_mgmt_app_bucket" {
  bucket = "hydroserver-data-mgmt-app-${var.instance}-${data.aws_caller_identity.current.account_id}"
}

resource "aws_s3_bucket" "hydroserver_api_storage_bucket" {
  bucket = "hydroserver-api-storage-${var.instance}-${data.aws_caller_identity.current.account_id}"
}

# resource "aws_s3_bucket" "hydroserver_django_bucket" {
#   bucket = "hydroserver-django-${var.instance}-${data.aws_caller_identity.current.account_id}"
# }

# ------------------------------------------------ #
# HydroServer S3 Restrict Public Access            #
# ------------------------------------------------ #

resource "aws_s3_bucket_public_access_block" "hydroserver_data_mgmt_app_bucket" {
  bucket = aws_s3_bucket.hydroserver_data_mgmt_app_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "hydroserver_api_storage_bucket" {
  bucket = aws_s3_bucket.hydroserver_api_storage_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# resource "aws_s3_bucket_public_access_block" "hydroserver_django_bucket" {
#   bucket = aws_s3_bucket.hydroserver_django_bucket.id

#   block_public_acls       = true
#   block_public_policy     = true
#   ignore_public_acls      = true
#   restrict_public_buckets = true
# }

# ------------------------------------------------ #
# HydroServer S3 Ownership Controls                #
# ------------------------------------------------ #

resource "aws_s3_bucket_ownership_controls" "hydroserver_data_mgmt_app_bucket" {
  bucket = aws_s3_bucket.hydroserver_data_mgmt_app_bucket.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
  depends_on = [aws_s3_bucket_public_access_block.hydroserver_data_mgmt_app_bucket]
}

resource "aws_s3_bucket_ownership_controls" "hydroserver_api_storage_bucket" {
  bucket = aws_s3_bucket.hydroserver_api_storage_bucket.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
  depends_on = [aws_s3_bucket_public_access_block.hydroserver_api_storage_bucket]
}

# ------------------------------------------------ #
# HydroServer Data Management App Configuration    #
# ------------------------------------------------ #

resource "aws_s3_object" "hydroserver_data_mgmt_app_index_html" {
  bucket       = aws_s3_bucket.hydroserver_data_mgmt_app_bucket.id
  key          = "index.html"
  source       = "data_mgmt_app_index.html"
  content_type = "text/html"
}

# ------------------------------------------------ #
# HydroServer S3 Bucket Policies                   #
# ------------------------------------------------ #

resource "aws_s3_bucket_policy" "hydroserver_data_mgmt_app_bucket" {
  bucket = aws_s3_bucket.hydroserver_data_mgmt_app_bucket.id
  policy = jsonencode({
    Version = "2008-10-17"
    Id      = "PolicyForCloudFrontPrivateContent"
    Statement = [
      {
        Sid    = "AllowCloudFrontServicePrincipal"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.hydroserver_data_mgmt_app_bucket.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.hydroserver_distribution.arn
          }
        }
      }
    ]
  })

  depends_on = [
    aws_cloudfront_distribution.hydroserver_distribution,
    aws_s3_bucket_public_access_block.hydroserver_data_mgmt_app_bucket
  ]
}

resource "aws_s3_bucket_policy" "hydroserver_api_storage_bucket" {
  bucket = aws_s3_bucket.hydroserver_api_storage_bucket.id
  policy = jsonencode({
    Version = "2008-10-17"
    Id      = "PolicyForCloudFrontPrivateContent"
    Statement = [
      {
        Sid    = "AllowCloudFrontServicePrincipal"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.hydroserver_api_storage_bucket.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.hydroserver_distribution.arn
          }
        }
      }
    ]
  })

  depends_on = [
    aws_cloudfront_distribution.hydroserver_distribution,
    aws_s3_bucket_public_access_block.hydroserver_api_storage_bucket
  ]
}

# ------------------------------------------------ #
# HydroServer S3 API Storage Folders               #
# ------------------------------------------------ #

resource "aws_s3_object" "media_folder" {
  bucket = aws_s3_bucket.hydroserver_api_storage_bucket.id
  key    = "photos/"
}

resource "aws_s3_object" "static_folder" {
  bucket = aws_s3_bucket.hydroserver_api_storage_bucket.id
  key    = "static/"
}
