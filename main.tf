# # iam.tf | IAM Role Policies

resource "aws_iam_role" "ecsTaskExecutionRole" {
  name               = var.ecs_role_name
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
  tags               = var.role_tags
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "ecsTaskExecutionRole_policy" {
  role       = aws_iam_role.ecsTaskExecutionRole.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_ecs_cluster" "aws-ecs-cluster" {
  name = var.ecs_cluster_name
  tags = var.ecs_cluster_tags
}

resource "aws_ecs_task_definition" "aws-ecs-task" {
  family                   = "${var.app_name}-task"
  requires_compatibilities = var.requires_compatibilities
  cpu                      = var.cpu_size
  memory                   = var.memory_size
  network_mode             = var.network_mode
  tags                     = var.ecs_tags
  execution_role_arn       = aws_iam_role.ecsTaskExecutionRole.arn
  task_role_arn            = aws_iam_role.ecsTaskExecutionRole.arn
  container_definitions    = <<TASK_DEFINITION
  [
    {
      "name": "iis",
      "image": "mcr.microsoft.com/windows/servercore/iis",
      "memory": 2048,
      "essential": true

    }
  ]
  TASK_DEFINITION
  runtime_platform {
    operating_system_family = "WINDOWS_SERVER_2019_CORE"
    cpu_architecture        = "X86_64"
  }

}

resource "aws_ecs_service" "ecs_service" {
  name            = "${var.app_name}-service"
  cluster         = aws_ecs_cluster.aws-ecs-cluster.arn
  task_definition = aws_ecs_task_definition.aws-ecs-task.arn
  network_configuration {
    security_groups = var.security_groups
    subnets         = var.subnets
  }
}