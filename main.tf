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
  cidr_block              = "${cidrsubnet(aws_vpc.terraform-vpc.cidr_block, 8, 0)}"
  vpc_id                  = "${aws_vpc.terraform-vpc.id}"
  availability_zone       = "${var.region-az-a}"
  map_public_ip_on_launch = "true"

  tags = {
    Name = "${var.project}_subnet_mgmt_region-az-a"
    UK-SE = "${var.se-name}"
  }
}

# --- CREATE TRAFFIC SUBNET AZ-A
resource "aws_subnet" "traffic" {
  cidr_block              = "${cidrsubnet(aws_vpc.terraform-vpc.cidr_block, 8, 1)}"
  vpc_id                  = "${aws_vpc.terraform-vpc.id}"
  availability_zone       = "${var.region-az-a}"
  map_public_ip_on_launch = "true"

  tags = {
    Name = "${var.project}_subnet_traffic_region-az-a"
    UK-SE = "${var.se-name}"
  }
}

# --- CREATE INTERNET GATEWAY
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
  route_table_id = "${aws_route_table.internet_rt.id}"
  subnet_id      = "${aws_subnet.mgmt.id}"
}
resource "aws_route_table_association" "traffic_rt" {
  route_table_id = "${aws_route_table.internet_rt.id}"
  subnet_id      = "${aws_subnet.traffic.id}"
}

# --- CREATE SECUIRTY GROUP FOR MGMT INTERFACE
resource "aws_security_group" "bigip-sg-mgmt" {
  name        = "bigip-sg-mgmt"
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
  name        = "bigip-sg-traffic"
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

# --- GET F5 AMI ID
data "aws_ami" "f5_ami" {
  most_recent = true
  owners      = ["679593333241"]

  filter {
    name   = "name"
    values = ["F5*BIGIP-14.1.2*PAYG-Best*10*"]
  }
}

# --- CREATE RANDOM PASSWORD
resource "random_string" "password" {
  length           = 16
  special          = true
  override_special = "@"
}

# --- CREATE INTERFACE - BIG-IP MGMT
resource "aws_network_interface" "mgmt" {
  subnet_id       = aws_subnet.mgmt.id
  security_groups = [aws_security_group.bigip-sg-mgmt.id]
}

# --- CREATE ELASTIC IP FOR BIG-IP MGMT
resource "aws_eip" "mgmt" {
  network_interface = aws_network_interface.mgmt.id
  vpc               = true
}

# --- CREATE INTERFACE - BIG-IP TRAFFIC
resource "aws_network_interface" "traffic" {
  subnet_id       = aws_subnet.traffic.id
  security_groups = [aws_security_group.bigip-sg-traffic.id]
}

# --- CREATE ELASTIC IP FOR BIG-IP TRAFFIC
resource "aws_eip" "traffic" {
  network_interface = aws_network_interface.traffic.id
  vpc               = true
}

# --- DEPLOY BIG-IP USING DISCOVERED AMI
resource "aws_instance" "f5_bigip" {
  instance_type = var.ec2_instance_type
  ami           = data.aws_ami.f5_ami.id
  key_name      = var.ec2_key_name

  root_block_device {
    delete_on_termination = true
  }

  # -- ATTACH MGMT INTERFACE
  network_interface {
    network_interface_id = "${aws_network_interface.mgmt.id}"
    device_index         = 0
  }

  # -- ATTACH TRAFFIC INTERFACE
  network_interface {
    network_interface_id = "${aws_network_interface.traffic.id}"
    device_index         = 1
  }

  # -- BUILD 'USER DATA' FILE FROM TEMPLATE
  user_data = templatefile(
    "${path.module}/f5_onboard.tmpl",
    {
      DO_URL      = var.DO_URL,
      AS3_URL     = var.AS3_URL,
      libs_dir    = var.libs_dir,
      onboard_log = var.onboard_log,
      PWD         = random_string.password.result
    }
  )

  depends_on = [aws_eip.mgmt]

  tags = {
    Name = "${var.project}_bigip_1"
    UK-SE = "${var.se-name}"
  }
}
