# --- THE FOLLOWING VARIABLES MUST BE MODIFIED PER DEPLOYMENT

variable "f5_instance_count" {
  description = "Number of BIG-IPs to deploy"
  type        = number
  default     = 1
}

variable "project" {
  description = "project name to use for tags"
  default     = "terra-aws-poc"
}

variable "se-name" {
  description = "UK SE name to use for tags"
  default     = "arch"
}

variable "ec2_key_name" {
  description = "AWS EC2 Key name for SSH access"
  type        = string
  default = "arch_id_rsa"
}

# Please check and update the latest DO URL from https://github.com/F5Networks/f5-declarative-onboarding/releases
# always point to a specific version in order to avoid inadvertent configuration inconsistency
variable DO_URL {
  description = "URL to download the BIG-IP Declarative Onboarding module"
  type        = string
  default     = "https://github.com/F5Networks/f5-declarative-onboarding/releases/download/v1.7.0/f5-declarative-onboarding-1.7.0-3.noarch.rpm"
}

# Please check and update the latest AS3 URL from https://github.com/F5Networks/f5-appsvcs-extension/releases/latest 
# always point to a specific version in order to avoid inadvertent configuration inconsistency
variable AS3_URL {
  description = "URL to download the BIG-IP Application Service Extension 3 (AS3) module"
  type        = string
  default     = "https://github.com/F5Networks/f5-appsvcs-extension/releases/download/v3.14.0/f5-appsvcs-3.14.0-4.noarch.rpm"
}

# --- THE FOLLOWING VARIABLES DO NOT HAVE TO BE MODIFIED PER DEPLOYMENT, BUT CAN IF REQUIRED

variable "aws_region" {
  description = "aws region"
  default     = "eu-west-2"
}

variable "region-az-a" {
  description = "This becomes az_a"
  default     = "eu-west-2a"
}

variable "region-az-b" {
  description = "This becomes az_b"
  default     = "eu-west-2b"
}

variable "region-az-c" {
  description = "This becomes az_c"
  default     = "eu-west-2c"
}

variable "f5_ami_search_name" {
  description = "BIG-IP AMI name to search for"
  type        = string
  default     = "F5 Networks BIGIP-14.* PAYG - Best 200Mbps*"
}

variable "cidr" {
  description = "CIDR block for VPC"
  default     = "10.2.0.0/16"
}

variable "mgmt_ports" {
  description = "CIDR block for VPC"
  default     = ["22", "443"]
}

variable "vs_ports" {
  description = "CIDR block for VPC"
  default     = ["80", "443"]
}

variable "ec2_instance_type" {
  description = "AWS EC2 instance type"
  type        = string
  default     = "m5.large"
}

variable "vpc_public_subnet_ids" {
  description = "AWS VPC Subnet id for the public subnet"
  type        = list
  default     = []
}

variable "vpc_private_subnet_ids" {
  description = "AWS VPC Subnet id for the private subnet"
  type        = list
  default     = []
}

variable "mgmt_eip" {
  description = "Enable an Elastic IP address on the management interface"
  type        = bool
  default     = true
}

variable "mgmt_subnet_security_group_ids" {
  description = "AWS Security Group ID for BIG-IP management interface"
  type        = list
  default     = []
}

variable "public_subnet_security_group_ids" {
  description = "AWS Security Group ID for BIG-IP public interface"
  type        = list
  default     = []
}

variable "private_subnet_security_group_ids" {
  description = "AWS Security Group ID for BIG-IP private interface"
  type        = list
  default     = []
}

variable "libs_dir" {
  description = "Directory on the BIG-IP to download the A&O Toolchain into"
  type        = string
  default     = "/config/cloud/aws/node_modules"
}

variable onboard_log {
  description = "Directory on the BIG-IP to store the cloud-init logs"
  type        = string
  default     = "/var/log/startup-script.log"
}
