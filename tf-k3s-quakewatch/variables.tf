variable "project_name" {
  type    = string
  default = "quakewatch-k3s"
}

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "vpc_cidr" {
  type    = string
  default = "10.10.0.0/16"
}

variable "azs" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b"]
}

variable "public_subnets" {
  type    = list(string)
  default = ["10.10.1.0/24", "10.10.2.0/24"]
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "your_ip_cidr" {
  type = string
}

variable "quakewatch_image" {
  type    = string
  default = "alexsay23/quakewatch:latest"
}

variable "cluster_token" {
  type    = string
  default = "MySecureToken123456!"
}
