variable "EnvironmentName" {
  description = "Name of AWS Env"
  type        = string
  default     = "TAG-088"
}

variable "GroupStaff" {  # Shortened because var.length <33
  description = "Staff of the group who worked over the project"
  type        = string
  default     = "Petr,Prot,Zenk,Stad,Oryn,Lesk"
}
