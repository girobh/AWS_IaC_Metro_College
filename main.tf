#REGION
provider "aws" {
  region     = "us-east-2"
  access_key = "XXXXX"
  secret_key = "XXXXX"
}

# Create a new VPC
resource "aws_vpc" "lab_vpc" {
  cidr_block = "172.30.0.0/16"
  enable_dns_hostnames = true
  tags = {
    Name = "Lab VPC"
  }
}

# Create two public subnets in different availability zones
resource "aws_subnet" "public_subnet_1" {
  vpc_id = aws_vpc.lab_vpc.id
  cidr_block = "172.30.1.0/24"
  availability_zone = "us-east-2a"
  tags = {
    Name = "Public Subnet 1"
  }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id = aws_vpc.lab_vpc.id
  cidr_block = "172.30.2.0/24"
  availability_zone = "us-east-2b"
  tags = {
    Name = "Public Subnet 2"
  }
}

# Create an internet gateway and attach it to the VPC
resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.lab_vpc.id
  tags = {
    Name = "Internet Gateway"
  }
}

# Configure route tables for public subnets
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.lab_vpc.id
  tags = {
    Name = "Public Route Table"
  }
}

resource "aws_route" "public_internet_gateway" {
  route_table_id = aws_route_table.public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.internet_gateway.id
}

resource "aws_route_table_association" "public_subnet_1" {
  subnet_id = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "public_subnet_2" {
  subnet_id = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_route_table.id
}

# Create security groups
resource "aws_security_group" "ec2_sg" {
  name        = "ec2_security_group"
  description = "Security group for EC2 instances"
  vpc_id      = aws_vpc.lab_vpc.id
  tags = {
    Name = "EC2-SG"
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "alb_sg" {
  name        = "alb_security_group"
  description = "Security group for Application Load Balancer"
  vpc_id      = aws_vpc.lab_vpc.id
  tags = {
    Name = "ALB-SG"
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "rds_sg" {
  name        = "rds_security_group"
  description = "Security group for RDS instances"
  vpc_id      = aws_vpc.lab_vpc.id
  tags = {
    Name = "RDS-SG"
  }

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create an autoscaling launch configuration
resource "aws_launch_configuration" "EC2_Launch_Jenkins" {
  name          = "EC2_Launch_Jenkins"
  image_id      = "ami-0ddda618e961f2270"
  instance_type = "t2.micro"
  key_name      = "devops-project"
  associate_public_ip_address = true
  security_groups             = [aws_security_group.ec2_sg.id]
  
  user_data     = <<-EOF
                  #!/bin/bash
                  sudo echo "installing Jenkins"
                  sudo yum update -y
                  sudo amazon-linux-extras install java-openjdk11 -y
                  sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
                  sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
                  sudo yum upgrade
                  sudo yum install jenkins -y
                  sudo systemctl enable jenkins
                  sudo systemctl start jenkins
                  sudo systemctl status jenkins
                  
                  sudo echo "Installing Docker Compose"
                  sudo curl -L https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
                  sudo chmod +x /usr/local/bin/docker-compose
                  docker-compose version
                  
                  sudo echo "installing maven"
                  sudo wget https://repos.fedorapeople.org/repos/dchen/apache-maven/epel-apache-maven.repo -O /etc/yum.repos.d/epel-apache-maven.repo
                  sudo sed -i s/\$releasever/6/g /etc/yum.repos.d/epel-apache-maven.repo
                  sudo yum install -y apache-maven
                  
                  sudo echo "Installing Docker Daemon"
                  sudo yum update -y
                  sudo amazon-linux-extras install docker -y
                  sudo service docker start
                  sudo usermod -a -G docker ec2-user
                  newgrp docker
                  sudo service docker start
                  
                  sudo yum install git -y
                  EOF
}

# Create an autoscaling group
resource "aws_autoscaling_group" "my_asg" {
  launch_configuration = aws_launch_configuration.EC2_Launch_Jenkins.id
  min_size             = 2
  max_size             = 5
  desired_capacity     = 2
  vpc_zone_identifier = [
    aws_subnet.public_subnet_1.id,
    aws_subnet.public_subnet_2.id,
  ]
}

# Create an Application Load Balancer (ALB)
resource "aws_lb" "my_alb" {
  name               = "my-application-load-balancer"
  internal           = false
  load_balancer_type = "application"
  subnets            = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
}

# Create a target group for the ALB
resource "aws_lb_target_group" "my_target_group" {
  name     = "my-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.lab_vpc.id
}

# Create a listener for the ALB
resource "aws_lb_listener" "my_listener" {
  load_balancer_arn = aws_lb.my_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.my_target_group.arn
  }
}

# Create a private S3 bucket
resource "aws_s3_bucket" "igor-project-bucket-s3" {
  bucket = "igor-project-bucket-s3"
}

# Create an IAM role
resource "aws_iam_role" "igor_role" {
  name = "igor_ec2_role"
  
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "sts:AssumeRole"
            ],
            "Principal": {
                "Service": [
                    "ec2.amazonaws.com"
                ]
            }
        }
    ]
}
EOF
}

# Attach a policy to the IAM role
resource "aws_iam_policy" "igor_s3_full_access_policy" {
  name        = "igor_s3_full_access_policy"
  description = "Provides full access to S3"
  
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:*",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_policy_attachment" "s3_policy_attachment" {
  name        = "s3_policy_attachment"
  policy_arn  = aws_iam_policy.igor_s3_full_access_policy.arn
  roles       = [aws_iam_role.igor_role.name]
}

# Create two private subnets in different availability zones
resource "aws_subnet" "private_subnet_1" {
  vpc_id            = aws_vpc.lab_vpc.id
  cidr_block        = "172.30.3.0/24"
  availability_zone = "us-east-2a"
  tags = {
    Name = "Private Subnet 1"
  }
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id            = aws_vpc.lab_vpc.id
  cidr_block        = "172.30.4.0/24"
  availability_zone = "us-east-2b"
  tags = {
    Name = "Private Subnet 2"
  }
}

# Create a subnet group for RDS
resource "aws_db_subnet_group" "my_db_subnet_group" {
  name       = "my-db-subnet-group"
  subnet_ids = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
}

# Create an RDS instance
resource "aws_db_instance" "igor-database" {
  identifier            = "igor-database"
  allocated_storage     = 20
  storage_type          = "gp2"
  engine                = "mysql"
  engine_version        = "5.7"
  instance_class        = "db.t3.micro"
  username              = "admin"
  password              = "Metro123"
  db_subnet_group_name  = aws_db_subnet_group.my_db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  skip_final_snapshot   = true
}
