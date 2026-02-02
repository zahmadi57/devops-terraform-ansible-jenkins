variable "region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Tag/name prefix"
  type        = string
  default     = "zia-demo"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "ssh_key_name" {
  description = "Existing EC2 Key Pair name (required)"
  type        = string

  validation {
    condition     = length(var.ssh_key_name) > 0
    error_message = "ssh_key_name must be a non-empty EC2 Key Pair name."
  }
}

variable "allowed_ssh_cidr" {
  description = "CIDR allowed to SSH (use your public IP /32)"
  type        = string
  default     = "0.0.0.0/0"
}

