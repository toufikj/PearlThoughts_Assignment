include "root" {
  path   = find_in_parent_folders("root-config.hcl")
  expose = true
}

include "stage" {
  path   = find_in_parent_folders("prod.hcl")
  expose = true
}

locals {
  # merge tags
  local_tags = {
    "Developer" = "Toufik"
  }

  tags = merge(include.root.locals.root_tags, include.stage.locals.tags, local.local_tags)
}

generate "provider_global" {
  path      = "provider.tf"
  if_exists = "overwrite"
  contents  = <<EOF
terraform {
  backend "s3" {}
  required_version = "${include.root.locals.version_terraform}"
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "${include.root.locals.version_provider_aws}"
    }
  }
}

provider "aws" {
  region = "${include.root.locals.region}"
  # version = "= 5.70.0"
}
EOF
}

#############################################################################################
inputs = {
  region                = "ap-south-1"
  stage                 = "prod"
  vpc_id                = "vpc-08537c3ca047ee074"
  product               = "medusa"
  network_mode          = "awsvpc"
  container_name        = "medusa"
  container_port        = 9000
  container_protocol    = "tcp"
  cpu                   = "1024"
  memory                = "2048"
  container_image_uri   = "lscr.io/linuxserver/medusa:latest"
  existing_ecs_task_execution_role_arn = "arn:aws:iam::783764579443:role/ecsTaskExecutionRole"
  environment_variables = {
    SERViCE = "medusa"
  }
  desired_count         = 1
  security_group        = "sg-02179dfbd89637dcd"
  counts                = 1  # Number of ECR repositories to create
  names                 = ["medusa"]  # Names of the ECR repositories
  tags                  = local.tags
  db_name               = "medusa"           # Set your DB name
  db_username           = "masteruser"   
  public_subnets        = ["subnet-094555e147f68ef71", "subnet-0c24ea1274bad7020", "subnet-0a8f45edcb26833cb"] # <-- Add your public subnet IDs here
}


terraform {
  source = "${get_parent_terragrunt_dir("root")}}/../modules/aws/ecs_v3"  # Correct relative path to the Strapi module
}
