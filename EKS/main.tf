module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "jenkins-vpc"
  cidr = var.vpc_cidr

  azs = data.aws_availability_zones.azs.names

  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  enable_dns_hostnames = true
}

/*module "eks" {
  source = "terraform-aws-modules/eks/aws"

  cluster_name    = "my-eks-cluster"
  cluster_version = "1.30"

  cluster_endpoint_public_access = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_groups = {
    nodes = {
      min_size     = 1
      max_size     = 1
      desired_size = 1

      instance_type = ["t2.micro"]
    }
  }

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}*/

module "ecs" {
  source = "terraform-aws-modules/ecs/aws"

  cluster_name = "ecs-tf-demo-cluster"

  cluster_configuration = {
    execute_command_configuration = {
      logging = "OVERRIDE"
      log_configuration = {
        cloud_watch_log_group_name = "/aws/ecs/aws-ec2"
      }
    }
  }

  fargate_capacity_providers = {
    FARGATE = {
      default_capacity_provider_strategy = {
        weight = 100
      }
    }
  }

  services = {
    ecsdemo-frontend = {
      cpu    = 256
      memory = 1024

      # Container definition(s)
      container_definitions = {

        swiggy-app = {
          cpu       = 256
          memory    = 1024
          essential = true
          image     = "public.ecr.aws/n0y2x5a0/devops-demo-cicd:latest"
          port_mappings = [
            {
              name          = "swiggy-app"
              containerPort = 3000
              protocol      = "tcp"
            }
          ]

          # Example image used requires access to write to root filesystem
          readonly_root_filesystem = false

          enable_cloudwatch_logging = false
          memory_reservation        = 100
        }
      }

      task_exec_iam_role_arn = "arn:aws:iam::699475927716:role/ecsTaskExecutionRole"

      subnet_ids = module.vpc.public_subnets
      security_group_rules = {
        alb_ingress_3000 = {
          type                     = "ingress"
          from_port                = 0
          to_port                  = 0
          protocol                 = "tcp"
          cidr_blocks              = ["0.0.0.0/0"]
        }
        egress_all = {
          type        = "egress"
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = ["0.0.0.0/0"]
        }
      }
    }
  }

  tags = {
    Environment = "Development"
    Project     = "Example"
  }
}
