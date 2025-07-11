locals {
  environment = "production"
  brand = "Toufik"

  tags = {
    environment = local.environment
    developer   = "Toufik"
    brand = local.brand
  }
}