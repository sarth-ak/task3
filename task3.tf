provider "aws" {
region = "ap-south-1"
profile= "sarthak"
}
resource "aws_vpc" "main" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"
  enable_dns_hostnames="true"
  tags = {
    Name = "main"
  }
}
//creating the key
resource "tls_private_key" "this" {
  algorithm = "RSA"
}

module "key_pair"{
  source = "terraform-aws-modules/key-pair/aws"
  key_name   = "mykey5"
  public_key = tls_private_key.this.public_key_openssh
}
resource "aws_subnet" "subnet1" {
  vpc_id     = "${aws_vpc.main.id}"
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch="true"
  tags = {
    Name = "check"
  }
}
resource "aws_subnet" "subnet2" {
  vpc_id     = "${aws_vpc.main.id}"
  cidr_block = "10.0.2.0/24"
  availability_zone="ap-south-1a"
  tags = {
    Name = "try"
  }
}
resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.main.id}"

  tags = {
    Name = "main"
  }
}
resource "aws_security_group" "sg_for_wp" {
  name        = "allow_to_wp"
  description = "Allow_for_all"
  vpc_id      =   "${aws_vpc.main.id}"
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  //rule no 2
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags= {
         Name="trial"
  }
  //outbound rule
 egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_security_group" "sg_for_mysql" {
depends_on =[
  aws_security_group.sg_for_wp
]
  name        = "allow_to_mysql"
  description = "Allow_by_wp"
  vpc_id      =   "${aws_vpc.main.id}"
 
  
  ingress {
    description = "MYSQL"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups=["${aws_security_group.sg_for_wp.id}"]
  }
  tags= {
         Name="trial"
  }
  
}
resource "aws_route_table" "r" {
  vpc_id = "${aws_vpc.main.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }
  tags = {
    Name = "main"
  }
}
resource "aws_route_table_association" "a" {
 depends_on=[
aws_route_table.r
]
   route_table_id     = aws_route_table.r.id
   subnet_id = aws_subnet.subnet1.id
}
resource "aws_instance" "MY_WP" {
  ami           = "ami-0c3d500b591de7dd9"
  instance_type = "t2.micro"
  subnet_id= aws_subnet.subnet1.id
  key_name = "mykey5"
  associate_public_ip_address="true"
  vpc_security_group_ids=["${aws_security_group.sg_for_wp.id}"]
  tags = {
    Name = "MYWP_TAG"
  }
}
resource "aws_instance" "MY_SQL" {
  depends_on=[
aws_security_group.sg_for_mysql
]
  ami           = "ami-08706cb5f68222d09"
  instance_type = "t2.micro"
  key_name = "mykey5"
  subnet_id= aws_subnet.subnet2.id
  vpc_security_group_ids=["${aws_security_group.sg_for_mysql.id}"]
  tags = {
    Name = "MYSQL_TAG"
  } 
}
//EXTRAs
resource "aws_instance" "Bash_host" {
  depends_on=[
aws_security_group.sg_for_mysql
]
  ami           = "ami-052c08d70def0ac62"
  instance_type = "t2.micro"
  key_name = "mykey5"
  subnet_id= aws_subnet.subnet1.id
  vpc_security_group_ids=["${aws_security_group.sg_for_wp.id}"]
  tags = {
    Name = "bash_TAG"
  } 
}
