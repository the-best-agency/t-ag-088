variable "EnvironmentName" {
  description = "Name of AWS Env"
  type        = string
  default     = "TAG-088"
}

variable "VPC_CIDR" {
  description = "CIDR block for main VPC"
  type        = string
  default     = "10.10.0.0/16"
}

variable "GroupStaff" {  # Shortened because var.length <33
  description = "Staff of the group who worked over the project"
  type        = string
  default     = "Petr,Prot,Zenk,Stad,Oryn,Lesk"
}

variable "PublicSubnet1CIDR" {
  description = "CIDR block for Public worker Subnet 1"
  type        = string
  default     = "10.10.1.0/24"
}

variable "PublicSubnet2CIDR" {
  description = "CIDR block for Public worker Subnet 2"
  type        = string
  default     = "10.10.2.0/24"
}

variable "PolytechnicIP" {
  description = "IP Address of Lviv Polytechnic client"
  type        = string
  default     = "0.0.0.0/24"
}

variable "ImageId" {
  description = "Image ID for worker EC2 from Autoscaling Group"
  type        = string
  default     = "0.0.0.0/24"
}