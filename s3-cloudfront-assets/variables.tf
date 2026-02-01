variable "project_name" {
  description = "Unique name for the project (used for bucket name)"
  type        = string
}

variable "domain_name" {
  description = "Custom domain for CloudFront (e.g. assets.example.com)"
  type        = string
}

variable "cloudflare_zone_id" {
  description = "Cloudflare Zone ID"
  type        = string
}

variable "cloudflare_api_token" {
  description = "Cloudflare API Token with necessary permissions"
  type        = string
  sensitive   = true
}

variable "price_class" {
  description = "CloudFront price class"
  type        = string
  default     = "PriceClass_100"
}

variable "tags" {
  description = "Common resource tags"
  type        = map(string)
  default     = {}
}
