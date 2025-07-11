output "repository_urls" {
  description = "List of URLs for the created ECR repositories"
  value       = [for repo in aws_ecr_repository.ecr : repo.repository_url]
}

output "ecs_cluster_arn" {
  description = "The ARN of the ECS cluster created."
  value       = aws_ecs_cluster.ecs.arn
}

output "postgres_address" {
  description = "The address of the PostgreSQL instance."
  value       = aws_db_instance.postgres.address
}

output "postgres_port" {
  description = "The port of the PostgreSQL instance."
  value       = aws_db_instance.postgres.port
}

output "redis_address" {
  description = "The address of the Redis cluster."
  value       = aws_elasticache_cluster.redis.cache_nodes[0].address
}

output "redis_port" {
  description = "The port of the Redis cluster."
  value       = aws_elasticache_cluster.redis.cache_nodes[0].port
}
