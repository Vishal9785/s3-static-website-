terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region     = "us-east-2"
  access_key = "xxxxxxxxxxxxxxxxxxxx"
  secret_key = "xxxxxxxxxxxxxxxxxxxx"
}

# Step 1: Create the bucket
resource "aws_s3_bucket" "static_site" {
  bucket = "my-static-site-vishal-2025-unique"  # Must be globally unique
  force_destroy = true

  tags = {
    Name        = "StaticSite"
    Environment = "Dev"
  }
}

# Step 2: Website configuration (NEW way)
resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.static_site.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
}

# Step 3: Allow public access
resource "aws_s3_bucket_public_access_block" "access" {
  bucket = aws_s3_bucket.static_site.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Step 4: Attach public-read bucket policy
resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.static_site.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.static_site.arn}/*"
      }
    ]
  })
}

# Step 5: Upload static site files
resource "aws_s3_object" "site_files" {
  for_each = fileset("site", "**")

  bucket       = aws_s3_bucket.static_site.id
  key          = each.value
  source       = "site/${each.value}"
  etag         = filemd5("site/${each.value}")
  content_type = lookup({
    html = "text/html"
    css  = "text/css"
    js   = "application/javascript"
    png  = "image/png"
    jpg  = "image/jpeg"
    jpeg = "image/jpeg"
    svg  = "image/svg+xml"
    woff = "font/woff"
    woff2 = "font/woff2"
    ttf  = "font/ttf"
  }, lower(split(".", each.value)[length(split(".", each.value)) - 1]), "application/octet-stream")
}



