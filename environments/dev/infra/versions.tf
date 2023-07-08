terraform {
  required_version = ">=1.4.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.63.0"
    }

    local = {
      source  = "hashicorp/local"
      version = ">= 2.4.0"
    }
    
    time = {
      source = "hashicorp/time"
      version = "0.7.2"
    }
    
    null = {
      source = "hashicorp/null"
      version = "3.1.0"
    }
}
