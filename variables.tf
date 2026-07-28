variable "aws_region" {
  description = "AWS region to deploy resources into"
  type        = string
  default     = "us-east-2"
}

variable "project_name" {
  description = "Project name used for tagging and resource naming"
  type        = string
  default     = "velafi"
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
  default     = "dev"
}

# --- VPC ---

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "192.168.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets (one per AZ)"
  type        = list(string)
  default     = ["192.168.1.0/24", "192.168.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets (one per AZ)"
  type        = list(string)
  default     = ["192.168.101.0/24", "192.168.102.0/24"]
}

variable "availability_zones" {
  description = "Availability zones to spread subnets across"
  type        = list(string)
  default     = ["us-east-2a", "us-east-2b"]
}

# --- VPS (EC2) ---

variable "instance_type" {
  description = "EC2 instance type for the VPS"
  type        = string
  default     = "t3.micro"
}

variable "ami_id" {
  description = "AMI ID for the EC2 instance. If empty, latest Amazon Linux 2023 is used"
  type        = string
  default     = ""
}

variable "key_pair_name" {
  description = "Name of an existing EC2 key pair for SSH access"
  type        = string
  default     = ""
}

variable "ssh_allowed_cidr" {
  description = "CIDR block allowed to reach the VPS over SSH"
  type        = string
  default     = "0.0.0.0/0"
}

# --- RDS PostgreSQL ---

variable "db_name" {
  description = "Initial database name"
  type        = string
  default     = "velafi"
}

variable "db_username" {
  description = "Master username for the database"
  type        = string
  default     = "velafi_admin"
}

variable "db_password" {
  description = "Master password for the database. Provide via env or tfvars, never commit"
  type        = string
  sensitive   = true
}

variable "db_engine_version" {
  description = "PostgreSQL engine version"
  type        = string
  default     = "16.3"
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "Allocated storage for the database in GiB"
  type        = number
  default     = 20
}
