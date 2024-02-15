provider "aws" {
  region = "us-west-2"
  access_key = "########"
  secret_key = "######################################"
}

# resource "aws_instance" "terec2" {
#   ami           = "ami-0cf0e376c672104d6"
#   instance_type = "t2.micro"
#   key_name      = "test-keypair123"
#   tags = {"Name" ="terraserver"}
# }

resource "aws_vpc" "teravpc" {
    cidr_block = "111.0.0.0/16"
    tags = {
        Name = "terafformvpc"
    }
}

resource "aws_subnet" "pub_subnet" {
    vpc_id = aws_vpc.teravpc.id
    cidr_block = "111.0.1.0/24"
    availability_zone = "us-west-2a"
    tags = { Name = "Public-subnet" }

  
}

resource "aws_subnet" "priv_subnet" {
    vpc_id = aws_vpc.teravpc.id
    cidr_block = "111.0.2.0/24"
    availability_zone = "us-west-2b"
    tags = { Name = "Private-subnet" }
  
}
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.teravpc.id
  tags = {
    Name = "IGW"
  }
}
resource "aws_route_table" "pub_route" {
  vpc_id = aws_vpc.teravpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

#   route {
#     ipv6_cidr_block        = "::/0"
#     egress_only_gateway_id = aws_internet_gateway.igw.id
#   }

  tags = {
    Name = "pub-rtb"
  }
}
resource "aws_route_table_association" "pub-rtA" {
  subnet_id      = aws_subnet.pub_subnet.id
  route_table_id = aws_route_table.pub_route.id
}
# resource "aws_route_table_association" "IgwrtA" {
#   gateway_id     = aws_internet_gateway.igw.id
#   route_table_id = aws_route_table.bar.id
# }
resource "aws_security_group" "allow_web" {
  name        = "allow_wed_traffic"
  description = "Allow Web inbound traffic"
  vpc_id      = aws_vpc.teravpc.id

  ingress {
    description      = "HTTPS"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
 #   ipv6_cidr_blocks = [aws_vpc.main.ipv6_cidr_block]
  }
  ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  #  ipv6_cidr_blocks = [aws_vpc.main.ipv6_cidr_block]
  }
  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  #  ipv6_cidr_blocks = [aws_vpc.main.ipv6_cidr_block]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_web"
  }
}
resource "aws_network_interface" "webNetI" {
  subnet_id       = aws_subnet.pub_subnet.id
  private_ips     = ["111.0.1.25"]
  security_groups = [aws_security_group.allow_web.id]

#   attachment {
#     instance     = aws_instance.test.id
#     device_index = 1
#   }
}
resource "aws_eip" "eip" {
  domain                    = "vpc"
  network_interface         = aws_network_interface.webNetI.id
  associate_with_private_ip = "111.0.1.25"
  depends_on = [ aws_internet_gateway.igw ]
}
resource "aws_instance" "terec2" {
  ami           = "ami-01e82af4e524a0aa3"
  instance_type = "t2.micro"
  availability_zone = "us-west-2a"
  key_name      = "oregon_keypair"
  network_interface {
    network_interface_id = aws_network_interface.webNetI.id
    device_index         = 0
  }
   user_data = <<-EOF
            #!/bin/bash
            sudo yum update -y
            sudo yum install -y httpd
            sudo systemctl start httpd
            echo “BlueWave Training” > /var/www/html/index.html
            EOF
  tags = {"Name" ="terra-web-server"}
}
