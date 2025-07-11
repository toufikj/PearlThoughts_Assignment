# Create CloudWatch Log Group for Strapi
resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${var.stage}/${var.product}"
  retention_in_days = 7
}

# Store each required value as a separate secret
resource "aws_secretsmanager_secret" "port" {
  name = "${var.product}-port"
}
resource "aws_secretsmanager_secret_version" "port" {
  secret_id     = aws_secretsmanager_secret.port.id
  secret_string = tostring(var.container_port)
}

resource "aws_secretsmanager_secret" "postgres_host" {
  name = "${var.product}-postgres-host"
}
resource "aws_secretsmanager_secret_version" "postgres_host" {
  secret_id     = aws_secretsmanager_secret.postgres_host.id
  secret_string = aws_db_instance.postgres.address
}

resource "aws_secretsmanager_secret" "postgres_port" {
  name = "${var.product}-postgres-port"
}
resource "aws_secretsmanager_secret_version" "postgres_port" {
  secret_id     = aws_secretsmanager_secret.postgres_port.id
  secret_string = tostring(aws_db_instance.postgres.port)
}

resource "aws_secretsmanager_secret" "postgres_db" {
  name = "${var.product}-postgres-db"
}
resource "aws_secretsmanager_secret_version" "postgres_db" {
  secret_id     = aws_secretsmanager_secret.postgres_db.id
  secret_string = aws_db_instance.postgres.db_name
}

resource "aws_secretsmanager_secret" "postgres_user" {
  name = "${var.product}-postgres-user"
}
resource "aws_secretsmanager_secret_version" "postgres_user" {
  secret_id     = aws_secretsmanager_secret.postgres_user.id
  secret_string = aws_db_instance.postgres.username
}

resource "aws_secretsmanager_secret" "postgres_password" {
  name = "${var.product}-postgres-password"
}
resource "aws_secretsmanager_secret_version" "postgres_password" {
  secret_id     = aws_secretsmanager_secret.postgres_password.id
  secret_string = aws_db_instance.postgres.password
}

resource "aws_secretsmanager_secret" "redis_host" {
  name = "${var.product}-redis-host"
}
resource "aws_secretsmanager_secret_version" "redis_host" {
  secret_id     = aws_secretsmanager_secret.redis_host.id
  secret_string = aws_elasticache_cluster.redis.cache_nodes[0].address
}

resource "aws_secretsmanager_secret" "redis_port" {
  name = "${var.product}-redis-port"
}
resource "aws_secretsmanager_secret_version" "redis_port" {
  secret_id     = aws_secretsmanager_secret.redis_port.id
  secret_string = tostring(aws_elasticache_cluster.redis.cache_nodes[0].port)
}

# Create ECS Task Definition for Strapi
resource "aws_ecs_task_definition" "ecs" {
  family                   = "${var.stage}-${var.product}-task"
  execution_role_arn       = "arn:aws:iam::783764579443:role/ecsTaskExecutionRole"
  network_mode             = var.network_mode
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.cpu
  memory                   = var.memory

  container_definitions = jsonencode([{
    name      = var.container_name
    image     = var.container_image_uri
    essential = true
    portMappings = [{
      containerPort = var.container_port
      protocol      = var.container_protocol
    }]
    environment = concat(
      [
        {
          name  = "DISABLE_MEDUSA_ADMIN"
          value = "false"
        },
        {
          name  = "MEDUSA_WORKER_MODE"
          value = "server"
        },
        {
          name  = "PORT"
          value = tostring(var.container_port)
        },
        {
          name  = "POSTGRES_HOST"
          value = aws_db_instance.postgres.address
        },
        {
          name  = "POSTGRES_PORT"
          value = tostring(aws_db_instance.postgres.port)
        },
        {
          name  = "POSTGRES_DB"
          value = aws_db_instance.postgres.db_name
        },
        {
          name  = "POSTGRES_USER"
          value = aws_db_instance.postgres.username
        },
        {
          name  = "POSTGRES_PASSWORD"
          value = aws_db_instance.postgres.password
        },
        {
          name  = "REDIS_HOST"
          value = aws_elasticache_cluster.redis.cache_nodes[0].address
        },
        {
          name  = "REDIS_PORT"
          value = tostring(aws_elasticache_cluster.redis.cache_nodes[0].port)
        }
      ]
    )
    # Inject ARNs of secrets for DB and Redis
    secrets = [
      { name = "PORT"             valueFrom = aws_secretsmanager_secret.port.arn },
      { name = "POSTGRES_HOST"    valueFrom = aws_secretsmanager_secret.postgres_host.arn },
      { name = "POSTGRES_PORT"    valueFrom = aws_secretsmanager_secret.postgres_port.arn },
      { name = "POSTGRES_DB"      valueFrom = aws_secretsmanager_secret.postgres_db.arn },
      { name = "POSTGRES_USER"    valueFrom = aws_secretsmanager_secret.postgres_user.arn },
      { name = "POSTGRES_PASSWORD" valueFrom = aws_secretsmanager_secret.postgres_password.arn },
      { name = "REDIS_HOST"       valueFrom = aws_secretsmanager_secret.redis_host.arn },
      { name = "REDIS_PORT"       valueFrom = aws_secretsmanager_secret.redis_port.arn }
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.ecs.name
        "awslogs-region"        = var.region
        "awslogs-stream-prefix" = var.stage
      }
    }
  }])
  depends_on = [
    aws_secretsmanager_secret_version.port,
    aws_secretsmanager_secret_version.postgres_host,
    aws_secretsmanager_secret_version.postgres_port,
    aws_secretsmanager_secret_version.postgres_db,
    aws_secretsmanager_secret_version.postgres_user,
    aws_secretsmanager_secret_version.postgres_password,
    aws_secretsmanager_secret_version.redis_host,
    aws_secretsmanager_secret_version.redis_port
  ]
}

resource "aws_ecs_cluster" "ecs" {
  name  = "${var.stage}-${var.product}-cluster"
}

resource "aws_ecs_service" "ecs" {
  name            = "${var.stage}-${var.product}-service"
  cluster         = aws_ecs_cluster.ecs.arn
  task_definition = aws_ecs_task_definition.ecs.arn
  launch_type     = "FARGATE"
  desired_count   = var.desired_count

  network_configuration {
    subnets         = var.public_subnets
    security_groups = [var.security_group]
    assign_public_ip = true
  }
}

# PostgreSQL RDS
resource "random_password" "postgres" {
  length  = 16
  special = true
}

resource "aws_db_instance" "postgres" {
  allocated_storage    = 20
  engine               = "postgres"
  engine_version       = "15.7"
  instance_class       = "db.t3.micro"
  db_name              = var.db_name
  username             = var.db_username
  password             = random_password.postgres.result
  parameter_group_name = "default.postgres15"
  skip_final_snapshot  = true
  vpc_security_group_ids = [var.security_group]
  db_subnet_group_name   = aws_db_subnet_group.postgres.name
}

resource "aws_db_subnet_group" "postgres" {
  name       = "${var.product}-db-subnet-group"
  subnet_ids = var.public_subnets
}

# Redis (ElastiCache)
resource "aws_elasticache_subnet_group" "redis" {
  name       = "${var.product}-redis-subnet-group"
  subnet_ids = var.public_subnets
}

resource "aws_elasticache_cluster" "redis" {
  cluster_id           = "${var.product}-redis"
  engine               = "redis"
  node_type            = "cache.t3.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"
  subnet_group_name    = aws_elasticache_subnet_group.redis.name
  security_group_ids   = [var.security_group]
}
