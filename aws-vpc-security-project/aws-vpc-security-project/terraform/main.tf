# Terraform Infrastructure as Code
# AWS Secure VPC Architecture — 2-Tier Public/Private Design
# Reference: Abhishek Veeramalla AWS Zero to Hero

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.0"
}

provider "aws" {
  region = var.aws_region
}

# ─────────────────────────────────────────
# VPC
# ─────────────────────────────────────────
resource "aws_vpc" "secure_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name    = "${var.project_name}-vpc"
    Project = var.project_name
  }
}

# ─────────────────────────────────────────
# INTERNET GATEWAY
# ─────────────────────────────────────────
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.secure_vpc.id

  tags = {
    Name    = "${var.project_name}-igw"
    Project = var.project_name
  }
}

# ─────────────────────────────────────────
# PUBLIC SUBNETS (2 AZs)
# ─────────────────────────────────────────
resource "aws_subnet" "public_az1" {
  vpc_id                  = aws_vpc.secure_vpc.id
  cidr_block              = var.public_subnet_az1_cidr
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true # Public subnet — instances get public IP

  tags = {
    Name    = "${var.project_name}-public-subnet-az1"
    Type    = "Public"
    Project = var.project_name
  }
}

resource "aws_subnet" "public_az2" {
  vpc_id                  = aws_vpc.secure_vpc.id
  cidr_block              = var.public_subnet_az2_cidr
  availability_zone       = "${var.aws_region}b"
  map_public_ip_on_launch = true

  tags = {
    Name    = "${var.project_name}-public-subnet-az2"
    Type    = "Public"
    Project = var.project_name
  }
}

# ─────────────────────────────────────────
# PRIVATE SUBNETS (2 AZs)
# ─────────────────────────────────────────
resource "aws_subnet" "private_az1" {
  vpc_id                  = aws_vpc.secure_vpc.id
  cidr_block              = var.private_subnet_az1_cidr
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = false # CRITICAL: No public IP for private servers

  tags = {
    Name    = "${var.project_name}-private-subnet-az1"
    Type    = "Private"
    Project = var.project_name
  }
}

resource "aws_subnet" "private_az2" {
  vpc_id                  = aws_vpc.secure_vpc.id
  cidr_block              = var.private_subnet_az2_cidr
  availability_zone       = "${var.aws_region}b"
  map_public_ip_on_launch = false

  tags = {
    Name    = "${var.project_name}-private-subnet-az2"
    Type    = "Private"
    Project = var.project_name
  }
}

# ─────────────────────────────────────────
# NAT GATEWAY (in Public Subnet AZ1)
# ─────────────────────────────────────────
resource "aws_eip" "nat_eip" {
  domain = "vpc"

  tags = {
    Name    = "${var.project_name}-nat-eip"
    Project = var.project_name
  }
}

resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_az1.id # NAT GW lives in PUBLIC subnet

  tags = {
    Name    = "${var.project_name}-nat-gateway"
    Project = var.project_name
  }

  depends_on = [aws_internet_gateway.igw]
}

# ─────────────────────────────────────────
# ROUTE TABLES
# ─────────────────────────────────────────

# Public Route Table — routes to Internet Gateway
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.secure_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id # IGW = internet access
  }

  tags = {
    Name    = "${var.project_name}-public-route-table"
    Project = var.project_name
  }
}

# Private Route Table — routes to NAT Gateway (outbound only)
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.secure_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id # NAT GW = outbound only
  }

  tags = {
    Name    = "${var.project_name}-private-route-table"
    Project = var.project_name
  }
}

# Associate public subnets with public route table
resource "aws_route_table_association" "public_az1" {
  subnet_id      = aws_subnet.public_az1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_az2" {
  subnet_id      = aws_subnet.public_az2.id
  route_table_id = aws_route_table.public_rt.id
}

# Associate private subnets with private route table
resource "aws_route_table_association" "private_az1" {
  subnet_id      = aws_subnet.private_az1.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_az2" {
  subnet_id      = aws_subnet.private_az2.id
  route_table_id = aws_route_table.private_rt.id
}

# ─────────────────────────────────────────
# SECURITY GROUPS
# ─────────────────────────────────────────

# ALB Security Group — accepts traffic from internet
resource "aws_security_group" "alb_sg" {
  name        = "${var.project_name}-alb-sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = aws_vpc.secure_vpc.id

  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project_name}-alb-sg"
    Project = var.project_name
  }
}

# EC2 Security Group — ONLY accepts traffic from ALB
resource "aws_security_group" "ec2_sg" {
  name        = "${var.project_name}-ec2-private-sg"
  description = "Security group for private EC2 instances. Traffic from ALB only."
  vpc_id      = aws_vpc.secure_vpc.id

  ingress {
    description     = "HTTP from ALB only"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id] # ALB sg-id, not 0.0.0.0/0
  }

  ingress {
    description     = "HTTPS from ALB only"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    description = "Allow outbound for updates via NAT GW"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project_name}-ec2-private-sg"
    Project = var.project_name
  }
}

# ─────────────────────────────────────────
# APPLICATION LOAD BALANCER
# ─────────────────────────────────────────
resource "aws_lb" "alb" {
  name               = "${var.project_name}-alb"
  internal           = false # Internet-facing
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_az1.id, aws_subnet.public_az2.id] # PUBLIC subnets

  tags = {
    Name    = "${var.project_name}-alb"
    Project = var.project_name
  }
}

resource "aws_lb_target_group" "ec2_targets" {
  name     = "${var.project_name}-targets"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.secure_vpc.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 3
    path                = "/"
    protocol            = "HTTP"
  }

  tags = {
    Name    = "${var.project_name}-target-group"
    Project = var.project_name
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ec2_targets.arn
  }
}

# ─────────────────────────────────────────
# AUTO SCALING GROUP + LAUNCH TEMPLATE
# ─────────────────────────────────────────
resource "aws_launch_template" "private_server" {
  name_prefix   = "${var.project_name}-server-"
  image_id      = var.ami_id
  instance_type = var.instance_type

  network_interfaces {
    associate_public_ip_address = false # NO public IP
    security_groups             = [aws_security_group.ec2_sg.id]
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd
    systemctl start httpd
    systemctl enable httpd
    echo "<h1>Secure Private Server</h1><p>Hostname: $(hostname -f)</p><p>This server has NO public IP. You reached it through the Load Balancer.</p>" > /var/www/html/index.html
  EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name    = "${var.project_name}-private-server"
      Project = var.project_name
    }
  }
}

resource "aws_autoscaling_group" "private_asg" {
  name                = "${var.project_name}-asg"
  desired_capacity    = 2
  min_size            = 1
  max_size            = 4
  target_group_arns   = [aws_lb_target_group.ec2_targets.arn]
  vpc_zone_identifier = [aws_subnet.private_az1.id, aws_subnet.private_az2.id] # PRIVATE subnets

  launch_template {
    id      = aws_launch_template.private_server.id
    version = "$Latest"
  }

  tag {
    key                 = "Project"
    value               = var.project_name
    propagate_at_launch = true
  }
}
