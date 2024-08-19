provider "aws" {
  region = "us-east-1"
}

# Create ECS Cluster
resource "aws_ecs_cluster" "ecs_cluster" {
  name = "my-ecs-cluster"
}

# Create ECR Repositories
resource "aws_ecr_repository" "notification_api" {
  name = "notification-api"
}

resource "aws_ecr_repository" "email_sender" {
  name = "email-sender"
}

# Define ECS Task Definitions
resource "aws_ecs_task_definition" "notification_api" {
  family                = "notification-api-task"
  network_mode          = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                   = "256"
  memory                = "512"

  container_definitions = jsonencode([{
    name      = "notification-api"
    image     = "${aws_ecr_repository.notification_api.repository_url}:latest"
    cpu       = 256
    memory    = 512
    essential = true
    portMappings = [
      {
        containerPort = 80
        hostPort      = 80
      }
    ]
  }])
}

resource "aws_ecs_task_definition" "email_sender" {
  family                = "email-sender-task"
  network_mode          = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                   = "256"
  memory                = "512"

  container_definitions = jsonencode([{
    name      = "email-sender"
    image     = "${aws_ecr_repository.email_sender.repository_url}:latest"
    cpu       = 256
    memory    = 512
    essential = true
    portMappings = [
      {
        containerPort = 80
        hostPort      = 80
      }
    ]
  }])
}

# Create ECS Services
resource "aws_ecs_service" "notification_api_service" {
  name            = "notification-api-service"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.notification_api.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  
  network_configuration {
    subnets          = ["subnet-12345678"] # Replace with your subnet ID
    assign_public_ip = true
    security_groups  = ["sg-12345678"]     # Replace with your security group ID
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.notification_api_target_group.arn
    container_name   = "notification-api"
    container_port   = 80
  }
}

resource "aws_ecs_service" "email_sender_service" {
  name            = "email-sender-service"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.email_sender.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  
  network_configuration {
    subnets          = ["subnet-12345678"] # Replace with your subnet ID
    assign_public_ip = true
    security_groups  = ["sg-12345678"]     # Replace with your security group ID
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.email_sender_target_group.arn
    container_name   = "email-sender"
    container_port   = 80
  }
}

# Create Application Load Balancer
resource "aws_lb" "application_load_balancer" {
  name               = "application-load-balancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["sg-12345678"] # Replace with your security group ID
  subnets            = ["subnet-12345678"] # Replace with your subnet ID
  enable_deletion_protection = false
}

# Create Target Groups
resource "aws_lb_target_group" "notification_api_target_group" {
  name     = "notification-api-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "vpc-12345678" # Replace with your VPC ID
}

resource "aws_lb_target_group" "email_sender_target_group" {
  name     = "email-sender-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "vpc-12345678" # Replace with your VPC ID
}

# Create CloudWatch Alarms for Auto-Scaling
resource "aws_cloudwatch_metric_alarm" "cpu_utilization" {
  alarm_name                = "cpu-utilization-alarm"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods         = "1"
  metric_name                = "CPUUtilization"
  namespace                  = "AWS/ECS"
  period                     = "60"
  statistic                  = "Average"
  threshold                  = "70"
  alarm_description          = "This metric monitors CPU utilization"
  dimensions = {
    ClusterName = aws_ecs_cluster.ecs_cluster.name
    ServiceName = aws_ecs_service.notification_api_service.name
  }
  alarm_actions = [
    aws_autoscaling_policy.scale_up_policy.arn
  ]
}
