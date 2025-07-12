# Create CloudWatch Log Group for Strapi
resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${var.stage}/${var.product}"
  retention_in_days = 7
}

resource "aws_secretsmanager_secret" "database_url" {
  name = "${var.product}-database-url-v3"
}
resource "aws_secretsmanager_secret_version" "database_url" {
  secret_id     = aws_secretsmanager_secret.database_url.id
  secret_string = "postgres://${aws_db_instance.postgres.username}:${random_password.postgres.result}@${aws_db_instance.postgres.address}:${aws_db_instance.postgres.port}/${aws_db_instance.postgres.db_name}"
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
  environment = [
    {
      name  = "NODE_ENV"
      value = "production"
    },
    {
      name  = "DISABLE_MEDUSA_ADMIN"
      value = "true"
    },
    {
      name  = "MEDUSA_WORKER_MODE"
      value = "server"
    },
    {
      name  = "PORT"
      value = tostring(var.container_port)
    }
  ]
  secrets = [
    {
      name      = "DATABASE_URL"
      valueFrom = aws_secretsmanager_secret.database_url.arn
    }
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
  special = false
  upper   = true
  lower   = true
  numeric = true
}

resource "aws_db_instance" "postgres" {
  identifier            = "${var.product}-postgres" # Give a name to the RDS instance
  allocated_storage     = 20
  engine                = "postgres"
  engine_version        = "15.7"
  instance_class        = "db.t3.micro"
  db_name               = var.db_name
  username              = var.db_username
  password              = random_password.postgres.result
  parameter_group_name  = "default.postgres15"
  skip_final_snapshot   = true
  vpc_security_group_ids = [var.security_group]
  db_subnet_group_name    = aws_db_subnet_group.postgres.name
  publicly_accessible     = true # Make RDS publicly accessible
}

resource "aws_db_subnet_group" "postgres" {
  name       = "${var.product}-db-subnet-group"
  subnet_ids = var.public_subnets
}

