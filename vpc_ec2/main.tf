provider "aws" {
  profile = "personalAccount"
}

#VPC Creation
resource "aws_vpc" "vpc" {
  cidr_block                        = "10.3.0.0/16"
  enable_dns_hostnames              = true
  enable_dns_support                = true

  tags = {
    Name = "Staging-VPC"
  }
}

#Subnet Creation
resource "aws_subnet" "public_subnets" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = element(var.public_subnet_cidrs, count.index)
  availability_zone       = element(var.azs, count.index)
  map_public_ip_on_launch = true

  tags = {
    Name = "Public Subnet ${count.index + 1}"
  }
}

#Internet Gateway Creation for Public Subnets
resource "aws_internet_gateway" "gw" {
 vpc_id = aws_vpc.vpc.id
 
 tags = {
   Name = "Staging VPC IG"
 }
}

#Route Table Creation for Public Subnets
resource "aws_route_table" "second_rt" {
 vpc_id = aws_vpc.vpc.id
 
 route {
   cidr_block = "0.0.0.0/0"
   gateway_id = aws_internet_gateway.gw.id
 }
 
 tags = {
   Name = "Staging VPC's 2nd Route Table"
 }
}

#Route Table Association
resource "aws_route_table_association" "public_subnet_asso" {
 count          = length(var.public_subnet_cidrs)
 subnet_id      = element(aws_subnet.public_subnets[*].id, count.index)
 route_table_id = aws_route_table.second_rt.id
}

#Security Group Creation
resource "aws_security_group" "SG_public_22_80_443" {
  name        = "SG_public_22_80_443"
  description = "Port 22, 80 and 443 from my ip"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description = "Allow SSH Traffic"
    from_port   = 22
    to_port     = 22
    protocol    = "TCP"
    cidr_blocks = ["${chomp(data.http.myip.response_body)}/32"]
  }

  ingress {
    description = "Allow HTTP Traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "TCP"
    cidr_blocks = ["${chomp(data.http.myip.response_body)}/32"]
  }

  ingress {
    description = "Allow HTTPS Traffic"
    from_port   = 443
    to_port     = 443
    protocol    = "TCP"
    cidr_blocks = ["${chomp(data.http.myip.response_body)}/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "SG_public_22_80_443"
  }
}

#Auto Scaling Group Creation
resource "aws_launch_configuration" "ec2_apache" {
  name_prefix     = "autoscaling-config"
  image_id        = "ami-0f318687928e8af0b"
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.SG_public_22_80_443.id]

  user_data = <<-EOL
  #cloud-boothook
  !#/bin/bash
  sudo yum update

  sudo yum -y install httpd
  sudo systemctl enable httpd
  sudo systemctl start httpd
  cd /var/www/html
  sudo mkdir Css
  sudo mkdir Scripts
  touch index.html
  sudo chmod 775 index.html
  sudo echo '<html> <body> <h1> Hello! Apache server successfully started! </h1> </body> </html>' > index.html
  EOL
  }

resource "aws_autoscaling_group" "autoscaling" {
  count                = length(var.public_subnet_cidrs)
  name_prefix          = "autoscaling"
  launch_configuration = aws_launch_configuration.ec2_apache.id
  min_size             = 1
  max_size             = 2
  vpc_zone_identifier  = [aws_subnet.public_subnets[count.index].id]
}
