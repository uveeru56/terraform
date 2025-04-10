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
  cidr_block = "12.0.0.0/23"
  tags = {
    Name = "terraform-vpc"
  }
}

#Create a new Subnet - public
resource "aws_subnet" "terraform_public_subnet" {
  vpc_id                  = aws_vpc.terraform_vpc.id
  map_public_ip_on_launch = true
  cidr_block              = "12.0.0.0/24"
  availability_zone       = "us-east-1a"
  tags = {
    Name = "terraform-public-subnet"
  }
}
#Create a new Subnet - private
resource "aws_subnet" "terraform_private_subnet" {
  vpc_id            = aws_vpc.terraform_vpc.id
  cidr_block        = "12.0.1.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "terraform-private-subnet"
  }
}

#Intenet Gateway
resource "aws_internet_gateway" "terraform_igw" {
  vpc_id = aws_vpc.terraform_vpc.id
  tags = {
    Name = "terraform-igw"
  }
}

# Route Table
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
resource "aws_route_table_association" "rt_assoc" {
  subnet_id      = aws_subnet.terraform_public_subnet.id
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

# Allow all outbound traffic
#resource "aws_network_acl_rule" "outbound_all" {
# network_acl_id = aws_network_acl.main_nacl.id
#rule_number    = 100
#egress         = true
#protocol       = "-1"   # all protocols
#rule_action    = "allow"
#cidr_block     = "0.0.0.0/0"
#from_port      = 0
#to_port        = 0
#}




# EC2 Instance
resource "aws_instance" "terraform_ec2" {
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
              echo "<h1>Deployed with Terraform</h1>" > /var/www/html/index.html
              EOF

  tags = {
    Name = "terraform-ec2"
  }
}