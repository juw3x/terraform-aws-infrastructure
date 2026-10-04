terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Uncomment and configure for remote state management
  # backend "s3" {
  #   bucket         = "your-terraform-state-bucket"
  #   key            = "devops-infrastructure/terraform.tfstate"
  #   region         = "us-east-1"
  #   encrypt        = true
  #   dynamodb_table = "terraform-locks"
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Owner       = var.owner
  }
}

# VPC Module
module "vpc" {
  source = "./modules/vpc"

  project_name          = var.project_name
  environment           = var.environment
  vpc_cidr              = var.vpc_cidr
  availability_zones    = var.availability_zones
  public_subnet_cidrs   = var.public_subnet_cidrs
  private_subnet_cidrs  = var.private_subnet_cidrs
  database_subnet_cidrs = var.database_subnet_cidrs
  enable_dns_hostnames  = true
  enable_dns_support    = true
  common_tags           = local.common_tags
}

# ALB Module
module "alb" {
  source = "./modules/alb"

  project_name        = var.project_name
  environment         = var.environment
  vpc_id              = module.vpc.vpc_id
  public_subnet_ids   = module.vpc.public_subnet_ids
  certificate_arn     = var.certificate_arn
  alb_internal        = var.alb_internal
  health_check_path   = var.health_check_path
  common_tags         = local.common_tags
  web_server_sg_id    = module.vpc.web_server_sg_id
}

# EC2 Module
module "ec2" {
  source = "./modules/ec2"

  project_name         = var.project_name
  environment          = var.environment
  vpc_id               = module.vpc.vpc_id
  public_subnet_ids    = module.vpc.public_subnet_ids
  private_subnet_ids   = module.vpc.private_subnet_ids
  instance_type        = var.instance_type
  ami_id               = var.ami_id
  key_name             = var.key_name
  min_size             = var.min_size
  max_size             = var.max_size
  desired_capacity     = var.desired_capacity
  common_tags          = local.common_tags
  security_group_ids   = [module.vpc.web_server_sg_id]
  target_group_arns    = [module.alb.target_group_arn]
}

# RDS Module
module "rds" {
  source = "./modules/rds"

  project_name         = var.project_name
  environment          = var.environment
  vpc_id               = module.vpc.vpc_id
  database_subnet_ids  = module.vpc.database_subnet_ids
  database_subnet_group_name = module.vpc.database_subnet_group_name
  db_instance_class    = var.db_instance_class
  db_engine            = var.db_engine
  db_engine_version    = var.db_engine_version
  db_name              = var.db_name
  db_username          = var.db_username
  db_password          = var.db_password
  allocated_storage    = var.allocated_storage
  multi_az             = var.multi_az
  common_tags          = local.common_tags
  security_group_ids   = [module.vpc.web_server_sg_id]
}

# S3 Module
module "s3" {
  source = "./modules/s3"

  project_name    = var.project_name
  environment     = var.environment
  bucket_name     = var.s3_bucket_name
  versioning      = var.s3_versioning
  common_tags     = local.common_tags
}
