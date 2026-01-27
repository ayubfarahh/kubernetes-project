variable "vpc_id" {
    type = string
  
}

variable "private_subnet_ids" {
    type = list(string)
}

variable "vpc_cidr" {
    type = string
  
}