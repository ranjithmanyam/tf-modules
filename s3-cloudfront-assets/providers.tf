provider "aws" {
  region = "eu-west-2"
}

provider "aws" {
  alias  = "use1"
  region = "us-east-1"
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}
