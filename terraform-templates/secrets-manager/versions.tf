terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }

  # Uncomment and configure for shared/remote state once a target backend is chosen.
  # backend "s3" {
  #   bucket = "my-terraform-state-bucket"
  #   key    = "secrets-manager/terraform.tfstate"
  #   region = "us-east-1"
  # }
}
