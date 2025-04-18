terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}
#Configure the AWS region
provider "aws" {
  region = "us-east-1"
}

# S3 Bucket for static website (private)
resource "aws_s3_bucket" "static_site" {
  bucket        = "jomotech-services-site"
  force_destroy = true

  website {
    index_document = "index.html"
    error_document = "error.html"
  }

  tags = {
    Name = "StaticWebsite"
  }
}

# Block all public access to the bucket
resource "aws_s3_bucket_public_access_block" "static_site_block" {
  bucket = aws_s3_bucket.static_site.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Origin Access Identity for CloudFront
resource "aws_cloudfront_origin_access_identity" "oai" {
  comment = "OAI for jomotech static site"
}

# S3 Bucket Policy to allow only CloudFront OAI
resource "aws_s3_bucket_policy" "allow_cloudfront_oai" {
  bucket = aws_s3_bucket.static_site.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          AWS = aws_cloudfront_origin_access_identity.oai.iam_arn
        },
        Action   = "s3:GetObject",
        Resource = "${aws_s3_bucket.static_site.arn}/*"
      }
    ]
  })
}

# CloudFront Distribution for the S3 site using OAI
resource "aws_cloudfront_distribution" "cdn" {
  origin {
    domain_name = aws_s3_bucket.static_site.bucket_regional_domain_name
    origin_id   = "s3-origin"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
    }
  }

  enabled             = true
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "s3-origin"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = {
    Environment = "production"
  }
}

# Output the CloudFront domain name
output "cloudfront_url" {
  value = aws_cloudfront_distribution.cdn.domain_name
}


#Keeps the S3 bucket private

#Uses CloudFront Origin Access Identity (OAI) to securely serve content

#Updates the S3 bucket policy after CloudFront is created
#Upload your site files using aws s3 sync . s3://jomotech-services-site