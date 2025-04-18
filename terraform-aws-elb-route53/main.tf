terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}
#Configure the AWS region
provider "aws" {
  region = "us-east-1"
}

#Create a new VPC
resource "aws_vpc" "terraform_vpc" {
  cidr_block = "172.17.0.0/23"
  tags = {
    Name = "terraform-vpc"
  }
}

#Create a new Subnet - public
resource "aws_subnet" "terraform_public_subnet" {
  vpc_id                  = aws_vpc.terraform_vpc.id
  map_public_ip_on_launch = true
  cidr_block              = "172.17.0.0/24"
  availability_zone       = "us-east-1a"
  tags = {
    Name = "terraform-public-subnet"
  }
}
#Create a new Subnet - public
resource "aws_subnet" "terraform_public_subnet1" {
  vpc_id            = aws_vpc.terraform_vpc.id
  cidr_block        = "172.17.1.0/24"
  availability_zone = "us-east-1b"
  tags = {
    Name = "terraform-public-subnet1"
  }
}

#Intenet Gateway
resource "aws_internet_gateway" "terraform_igw" {
  vpc_id = aws_vpc.terraform_vpc.id
  tags = {
    Name = "terraform-igw"
  }
}

# public subnet Route Table
resource "aws_route_table" "terraform_rt" {
  vpc_id = aws_vpc.terraform_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.terraform_igw.id
  }
  tags = {
    Name = "terraform-rt"
  }
}

# Associate Route Table to Subnet
resource "aws_route_table_association" "rt_assoc1" {
  subnet_id      = aws_subnet.terraform_public_subnet.id
  route_table_id = aws_route_table.terraform_rt.id
}

# Associate Route Table to Subnet
resource "aws_route_table_association" "rt_assoc2" {
  subnet_id      = aws_subnet.terraform_public_subnet1.id
  route_table_id = aws_route_table.terraform_rt.id
}



# Security Group
resource "aws_security_group" "terraform_sg" {
  name        = "terraform_sg"
  description = "Allow SSH and HTTP"
  vpc_id      = aws_vpc.terraform_vpc.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
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

  tags = {
    Name = "terraform-sg"
  }
}

# Network ACL
resource "aws_network_acl" "terraform_nacl" {
  vpc_id = aws_vpc.terraform_vpc.id
  tags = {
    Name = "terraform-nacl"
  }
}

# Allow inbound SSH (22), HTTP (80), and ephemeral ports (1024-65535)
resource "aws_network_acl_rule" "inbound_ssh" {
  network_acl_id = aws_network_acl.terraform_nacl.id
  rule_number    = 100
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 22
  to_port        = 22
}

resource "aws_network_acl_rule" "inbound_http" {
  network_acl_id = aws_network_acl.terraform_nacl.id
  rule_number    = 110
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 80
  to_port        = 80
}

resource "aws_network_acl_rule" "inbound_https" {
  network_acl_id = aws_network_acl.terraform_nacl.id
  rule_number    = 120
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 443
  to_port        = 443
}

resource "aws_network_acl_rule" "inbound_ephemeral" {
  network_acl_id = aws_network_acl.terraform_nacl.id
  rule_number    = 130
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

# Allow outbound SSH (22), HTTP (80), and ephemeral ports (1024-65535)
resource "aws_network_acl_rule" "outbound_ssh" {
  network_acl_id = aws_network_acl.terraform_nacl.id
  rule_number    = 100
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 22
  to_port        = 22
}

resource "aws_network_acl_rule" "outbound_http" {
  network_acl_id = aws_network_acl.terraform_nacl.id
  rule_number    = 110
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 80
  to_port        = 80
}

resource "aws_network_acl_rule" "outbound_https" {
  network_acl_id = aws_network_acl.terraform_nacl.id
  rule_number    = 120
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 443
  to_port        = 443
}

resource "aws_network_acl_rule" "outbound_ephemeral" {
  network_acl_id = aws_network_acl.terraform_nacl.id
  rule_number    = 130
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

# Associate NACL with Subnet
resource "aws_network_acl_association" "subnet_assoc" {
  subnet_id      = aws_subnet.terraform_public_subnet.id
  network_acl_id = aws_network_acl.terraform_nacl.id
}
# Associate NACL with Subnet
resource "aws_network_acl_association" "subnet_assoc1" {
  subnet_id      = aws_subnet.terraform_public_subnet1.id
  network_acl_id = aws_network_acl.terraform_nacl.id
}


# EC2 Instance
resource "aws_instance" "terraform_webserver1" {
  ami                         = "ami-00a929b66ed6e0de6"
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.terraform_public_subnet.id
  vpc_security_group_ids      = [aws_security_group.terraform_sg.id]
  associate_public_ip_address = true
  key_name                    = "jomo-key"
  user_data                   = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "<h1>Hello from server1: $(hostname -f)</h1>" > /var/www/html/index.html
              EOF

  tags = {
    Name = "terraform-webserver1"
  }
}

resource "aws_instance" "terraform_webserver2" {
  ami                         = "ami-00a929b66ed6e0de6"
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.terraform_public_subnet1.id
  vpc_security_group_ids      = [aws_security_group.terraform_sg.id]
  associate_public_ip_address = true
  key_name                    = "jomo-key"
  user_data                   = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "<h1>Hello from server2: $(hostname -f)</h1>" > /var/www/html/index.html
              EOF

  tags = {
    Name = "terraform-webserver2"
  }
}

# ALB
resource "aws_lb" "terraform_lb" {
  name               = "terraform-lb"
  internal           = false
  load_balancer_type = "application"
  subnets            = [aws_subnet.terraform_public_subnet.id,aws_subnet.terraform_public_subnet1.id]
  security_groups    = [aws_security_group.terraform_sg.id]
}

resource "aws_lb_target_group" "terraform_tg" {
  name     = "terraform-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.terraform_vpc.id
}

resource "aws_lb_target_group_attachment" "terraform_web_target_1" {
  target_group_arn = aws_lb_target_group.terraform_tg.arn
  target_id        = aws_instance.terraform_webserver1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "terraform_web_target_2" {
  target_group_arn = aws_lb_target_group.terraform_tg.arn
  target_id        = aws_instance.terraform_webserver2.id
  port             = 80
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.terraform_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.terraform_tg.arn
  }
}

#Route 53 Hosted Zone 
resource "aws_route53_zone" "terraform_route53_hostzone" {
  name = "jomotech.services"

  #tags = {
   # Environment = "production"
   # Project     = "web-app"
  #}
}
# Route 53 Record
resource "aws_route53_record" "web_record" {
  zone_id = aws_route53_zone.terraform_route53_hostzone.zone_id
  name    = "www.jomotech.services"
  type    = "A"

  alias {
    name                   = aws_lb.terraform_lb.dns_name
    zone_id                = aws_lb.terraform_lb.zone_id
    evaluate_target_health = true
  }
}
