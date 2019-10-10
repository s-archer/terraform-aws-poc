# Note that AWS creds should be stored in a vault, or locally in hidden folder: ~/.aws/credentials 

# --- DEFINE AWS PROVIDER
provider "aws" {
  region = "${var.aws_region}"
}

# --- CREATE VPC
resource "aws_vpc" "terraform-vpc" {
  cidr_block           = "${var.cidr}"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.se-name}-${var.project}-VPC"
    UK-SE = "${var.se-name}"
  }
}

# --- CREATE MGMT SUBNET AZ-A
resource "aws_subnet" "mgmt" {
  count                   = "${var.f5_instance_count}"
  cidr_block              = "${cidrsubnet(aws_vpc.terraform-vpc.cidr_block, 8, count.index)}"
  vpc_id                  = "${aws_vpc.terraform-vpc.id}"
  availability_zone       = "${var.region-az-a}"
  map_public_ip_on_launch = "true"

  tags = {
    Name = format("%s-subnet-mgmt-az-a-%d", var.project, count.index)
    UK-SE = "${var.se-name}"
  }
}

# --- CREATE TRAFFIC SUBNET AZ-A
resource "aws_subnet" "traffic" {
  count                   = "${var.f5_instance_count}"
  cidr_block              = "${cidrsubnet(aws_vpc.terraform-vpc.cidr_block, 8, count.index + var.f5_instance_count )}"
  vpc_id                  = "${aws_vpc.terraform-vpc.id}"
  availability_zone       = "${var.region-az-a}"
  map_public_ip_on_launch = "true"

  tags = {
    Name = format("%s-subnet-traffic-az-a-%d", var.project, count.index)
    UK-SE = "${var.se-name}"
  }
}

# --- CREATE IGW
resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.terraform-vpc.id}"

  tags = {
    Name = "${var.project}_internet_gateway"
    UK-SE = "${var.se-name}"
  }
}

# --- CREATE INTERNET ROUTE TABLE
resource "aws_route_table" "internet_rt" {
  vpc_id = "${aws_vpc.terraform-vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }

  tags = {
    Name = "${var.project}_internet_rt"
    UK-SE = "${var.se-name}"
  }
}

# --- ASSOCIATE SUBNETS WITH INTERNET ROUTE TABLE
resource "aws_route_table_association" "mgmt_rt" {
  count          = "${var.f5_instance_count}"
  route_table_id = "${aws_route_table.internet_rt.id}"
  subnet_id      = "${aws_subnet.mgmt[count.index].id}"
}
resource "aws_route_table_association" "traffic_rt" {
  count          = "${var.f5_instance_count}"
  route_table_id = "${aws_route_table.internet_rt.id}"
  subnet_id      = "${aws_subnet.traffic[count.index].id}"
}

# --- CREATE SECUIRTY GROUP FOR MGMT INTERFACE
resource "aws_security_group" "bigip-sg-mgmt" {
  count       = "${var.f5_instance_count}"
  name        = format("%s-bigip-sg-mgmt-%d", var.project, count.index)
  description = "allow access to and from the bigip mgmt IP"
  vpc_id      = "${aws_vpc.terraform-vpc.id}"

  ingress {
    protocol    = "tcp"
    from_port   = 22 
    to_port     = 22
    cidr_blocks  = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 443 
    to_port     = 443
    cidr_blocks  = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --- CREATE SECUIRTY GROUP FOR TRAFFIC INTERFACE
resource "aws_security_group" "bigip-sg-traffic" {
  count       = "${var.f5_instance_count}"
  name        = format("%s-bigip-sg-traffic-%d", var.project, count.index)
  description = "allow access to and from the bigip traffic IP"
  vpc_id      = "${aws_vpc.terraform-vpc.id}"

  ingress {
    protocol    = "tcp"
    from_port   = 80 
    to_port     = 80
    cidr_blocks  = ["0.0.0.0/0"]
  }
  
    ingress {
    protocol    = "tcp"
    from_port   = 443 
    to_port     = 443
    cidr_blocks  = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}


module bigip {
  source = "f5devcentral/bigip/aws"

  prefix                           = "${var.project}-bigip-"
  f5_instance_count                = var.f5_instance_count
  f5_ami_search_name               = "F5*BIGIP-14.1.2*PAYG-Best*10*"
  ec2_key_name                     = var.ec2_key_name
  mgmt_subnet_security_group_ids   = flatten([aws_security_group.bigip-sg-mgmt.*.id])
  public_subnet_security_group_ids = flatten([aws_security_group.bigip-sg-traffic.*.id])
  vpc_mgmt_subnet_ids              = flatten([aws_subnet.mgmt.*.id])
  vpc_public_subnet_ids            = flatten([aws_subnet.traffic.*.id])

}