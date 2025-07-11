# AWS region where the resources will be created
variable "region" {
  description = "The AWS region to deploy resources."
  type        = string
}

# Stage (dev, prod, etc.)
variable "stage" {
  description = "The environment name, e.g., dev or prod."
  type        = string
}

variable "product" {
  description = "The family of the ECS task definition."
  type        = string
}

# VPC ID where the resources will be deployed
variable "vpc_id" {
  description = "The ID of the VPC where the resources will be deployed."
  type        = string
}

# CPU allocation for the ECS Task
variable "cpu" {
  description = "CPU allocation for the ECS Task."
  type        = string
  
}

# Memory allocation for the ECS Task
variable "memory" {
  description = "Memory allocation for the ECS Task."
  type        = string
  
}

# Docker image for the Flowise container
variable "container_image_uri" {
  description = "The Docker image for the strapi container."
  type        = string
}

variable "container_port" {
  description = "The container port for strapi."
  type        = number
}

variable "container_protocol" {
  description = "The protocol used for the container (e.g., tcp)."
  type        = string
}

# Environment variables for the container
variable "environment_variables" {
  description = "Environment variables to be passed to the container."
  type        = map(string)
}

# Desired count for the ECS Service
variable "desired_count" {
  description = "The number of tasks desired for the ECS service."
  type        = number
}

# Security group for the ECS service
variable "security_group" {
  description = "The security group associated with the ECS service."
  type        = string
}


variable "network_mode" {
  description = "The network mode for the ECS task definition (e.g., awsvpc)."
  type        = string
}


variable "container_name" {
  description = "The name of the container for strapi."
  type        = string
}


variable "counts" {
  description = "Number of ECR repositories to create"
}

variable "names" {
  description = "List of names for ECR repositories"
  type        = list(string)
}


variable "public_subnets" {
  description = "List of public subnet IDs for DB and Redis."
  type        = list(string)
}

variable "db_username" {
  description = "Username for the PostgreSQL database."
  type        = string
}

variable "db_name" {
  description = "Database name for the PostgreSQL database."
  type        = string
}
