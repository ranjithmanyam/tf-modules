# S3 + CloudFront Assets Module

This Terraform module creates an S3 bucket to store static assets and a CloudFront distribution to serve those assets globally with low latency. It is designed for use in web applications that require efficient delivery of static content such as images, CSS, and JavaScript files.

	*	Amazon S3 (private bucket)
	*	Amazon CloudFront (CDN)
	*	AWS ACM (TLS certificate, DNS-validated)
	*	Cloudflare DNS
	*	Origin Access Control (OAC) — no public S3 access

## Features

✨ Features
	* Private S3 bucket (CloudFront-only access)
	* Global CDN via CloudFront
	* HTTPS with ACM certificates
	* Cloudflare DNS managed via Terraform
	* Modern OAC (replaces deprecated OAI)
	* Reusable & configurable
	* Works with Flask, Django, React, static sites

## Module Structure

```shell
s3-cloudfront-assets/
├── main.tf
├── variables.tf
├── outputs.tf
└── README.md
```
## Usage

```hcl
module "assets_cdn" {
  source = "./modules/s3-cloudfront-assets"

  providers = {
    aws        = aws
    aws.use1  = aws.use1
    cloudflare = cloudflare
  }

  project_name       = "example-assets"
  domain_name        = "assets.example.com"
  cloudflare_zone_id = var.cloudflare_zone_id

  tags = {
    Project = "example"
    Env     = "prod"
  }
}
```

## Example: Using in Flask

```python
ASSETS_BASE_URL = "https://assets.example.com"
```
```jinja2
<img src="{{ ASSETS_BASE_URL }}/assets/img/logo.png">
```
