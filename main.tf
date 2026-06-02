provider "aws" {
  region = var.aws_region
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"

  name = "projekat2-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b"]
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.10.0/24", "10.0.11.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true

  enable_dns_hostnames = true
  enable_dns_support   = true
}

resource "aws_security_group" "alb_sg" {
  name   = "alb-sg"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "backend_sg" {
  name   = "backend-sg"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port       = 5000
    to_port         = 5000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "db_sg" {
  name   = "db-sg"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.backend_sg.id]
  }
}

resource "aws_db_subnet_group" "db_subnets" {
  name       = "db-subnet-group"
  subnet_ids = module.vpc.private_subnets
}

resource "aws_db_instance" "mysql" {
  allocated_storage      = 20
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.db_subnets.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  skip_final_snapshot    = true
}

resource "aws_instance" "server_1" {
  ami                         = "ami-0c101f26f147fa7fd" 
  instance_type               = "t2.micro"
  subnet_id                   = module.vpc.private_subnets[0]
  vpc_security_group_ids      = [aws_security_group.backend_sg.id]
  associate_public_ip_address = false

  user_data = <<-EOF
              #!/bin/bash
              dnf update -y
              dnf install docker -y
              systemctl start docker
              systemctl enable docker
              usermod -a -G docker ec2-user
              sleep 15
              docker run -d -p 5000:5000 \
                -e DB_HOST=${split(":", aws_db_instance.mysql.endpoint)[0]} \
                -e DB_USER="${var.db_username}" \
                -e DB_PASSWORD="${var.db_password}" \
                -e DB_NAME="${var.db_name}" \
                --name moj-backend \
                lamijaahm/projekat2-backend:latest
              EOF

  tags = { Name = "Backend-Server-1" }
}

resource "aws_instance" "server_2" {
  ami                         = "ami-0c101f26f147fa7fd"
  instance_type               = "t2.micro"
  subnet_id                   = module.vpc.private_subnets[1]
  vpc_security_group_ids      = [aws_security_group.backend_sg.id]
  associate_public_ip_address = false

  user_data = <<-EOF
              #!/bin/bash
              dnf update -y
              dnf install docker -y
              systemctl start docker
              systemctl enable docker
              usermod -a -G docker ec2-user
              sleep 15
              docker run -d -p 5000:5000 \
                -e DB_HOST=${split(":", aws_db_instance.mysql.endpoint)[0]} \
                -e DB_USER="${var.db_username}" \
                -e DB_PASSWORD="${var.db_password}" \
                -e DB_NAME="${var.db_name}" \
                --name moj-backend \
                lamijaahm/projekat2-backend:latest
              EOF

  tags = { Name = "Backend-Server-2" }
}

resource "aws_lb_target_group" "backend_tg" {
  name     = "backend-tg"
  port     = 5000
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id

  health_check {
    path = "/api/proizvodi"
  }
}

resource "aws_lb_target_group_attachment" "attach_s1" {
  target_group_arn = aws_lb_target_group.backend_tg.arn
  target_id        = aws_instance.server_1.id
  port             = 5000
}

resource "aws_lb_target_group_attachment" "attach_s2" {
  target_group_arn = aws_lb_target_group.backend_tg.arn
  target_id        = aws_instance.server_2.id
  port             = 5000
}

resource "aws_lb" "moj_alb" {
  name               = "moj-projekat-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = module.vpc.public_subnets
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.moj_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend_tg.arn
  }
}

```
