provider "aws" {
  #access_key           = ""
  #secret_key           = ""
  region               = "eu-central-1"
}

# ========== VPC ==========
resource "aws_vpc" "main" {
  cidr_block           = var.VPC_CIDR
  instance_tenancy     = "default"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    "Name"             = var.EnvironmentName
    "Group"            = var.GroupStaff
  }
}

# ========== IGW ==========
resource "aws_internet_gateway" "main" {
    vpc_id             = aws_vpc.main.id
    
    tags = {
    "Name"             = "${var.EnvironmentName}-igw"
    "Group"            = var.GroupStaff
  }
}

resource "aws_eip" "nat_eip" {
  vpc        = true
  depends_on = [ aws_internet_gateway.main ]
}

# ===== Public subnets =====
resource "aws_subnet" "PublicSubnet1" {
  vpc_id = aws_vpc.main.id
  cidr_block = var.PublicSubnet1CIDR
  availability_zone = "eu-central-1a"
  map_public_ip_on_launch = true
  tags = {
    "Name" = "${var.EnvironmentName} Public Subnet (AZ0)"
    "Group" = var.GroupStaff
    "ResourceOwner" = "Oleksandr"
  }
}

resource "aws_subnet" "PublicSubnet2" {
  vpc_id = aws_vpc.main.id
  cidr_block = var.PublicSubnet2CIDR
  availability_zone = "eu-central-1b"
  map_public_ip_on_launch = true
  tags = {
    "Name" = "${var.EnvironmentName} Public Subnet (AZ1)"
    "Group" = var.GroupStaff
    "ResourceOwner" = "Oleksandr"
  }
}

# Routing tables to route traffic for Public Subnet
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    "Name" = "${var.EnvironmentName} Public RT"
    "Group" = "${var.EnvironmentName}"
  }
}
# Route for Internet Gateway
resource "aws_route" "public_internet_gateway" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}
# Route table associations for Public Subnets
resource "aws_route_table_association" "public1" {
  #count = 1
  subnet_id      = aws_subnet.PublicSubnet1.id
  route_table_id = aws_route_table.public.id
}
resource "aws_route_table_association" "public2" {
  #count = 1
  subnet_id      = aws_subnet.PublicSubnet2.id
  route_table_id = aws_route_table.public.id
}


# ========== SGs ===========
resource "aws_security_group" "ALBSecurityGroup" {
  name        = "ALBSecurityGroup"
  description = "Allow ingress from approved IPs"
  vpc_id      = aws_vpc.main.id
  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = [ var.PolytechnicIP ]
  }
  ingress {
    from_port        = 0
    to_port          = 0
    protocol         = -1
    cidr_blocks      = [ var.PolytechnicIP ]
  } 
   egress {
    from_port        = 0
    to_port          = 0
    protocol         = -1
    cidr_blocks      = [ "0.0.0.0/0" ]
  }
  tags = {
    "Name"  = "ALBSecurityGroup"
    "Group" = var.GroupStaff
  }
}

resource "aws_security_group" "ec2poolSG" {
  name        = "ec2poolSG"
  description = "Allows access to ec2 asg instances"
  vpc_id      = aws_vpc.main.id
  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = [ var.PolytechnicIP ]
    security_groups = [ aws_security_group.ALBSecurityGroup.id ]
  }
  ingress {
    from_port        = 3306
    to_port          = 3306
    protocol         = "tcp"
    cidr_blocks      = [ var.PolytechnicIP ]
  }
  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = [ var.PolytechnicIP ]
  }
  ingress {
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = [ var.PolytechnicIP ]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = -1
    cidr_blocks      = [ "0.0.0.0/0" ]
  }
  tags = {
    "Name" = "ec2_pool"
    "Group" = "${var.EnvironmentName}"
    "ResourceOwner" = "Oleksandr"
  }
}

# ===== Load Balancer ======
resource "aws_lb" "ApplicationLoadBalancer" {
  name               = "ApplicationLoadBalancer"
  internal           = false
  load_balancer_type = "application"

  enable_deletion_protection = false
  security_groups = [ aws_security_group.ALBSecurityGroup.id ]

  subnets            = [ aws_subnet.PublicSubnet1.id, aws_subnet.PublicSubnet2.id ]
  tags = {
    "Name" = "${var.EnvironmentName}-ApplicationLoadBalancer"
    "ResourceOwner" = "Oleksandr"
  }
}
  # -----
resource "aws_lb_listener" "Listener1" {
  load_balancer_arn = aws_lb.ApplicationLoadBalancer.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.LBTargetGroup.arn
  }
}

resource "aws_lb_listener" "Listener2" {
  load_balancer_arn = aws_lb.ApplicationLoadBalancer.arn
  port              = "443"
  protocol          = "HTTP"
  #ssl_policy = 

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.LBTargetGroup.arn
  }
}
resource "aws_lb_target_group" "LBTargetGroup" {
  name        = "LBTargetGroup"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  
  health_check {
    timeout = 5.0
    interval = 10.0
    healthy_threshold = 2.0
  }

  tags = {
    "Name" = "${var.EnvironmentName}-LBTargetGroup"
    "ResourceOwner" = "Oleksandr"
  }
}









