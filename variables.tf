variable "aws_region" {
  default = "ap-northeast-2"
}

variable "cluster-name" {
  default = "my-cluster"
  type    = string
}

variable "dbpassword" {
  default = "password"
}

variable "key_name" {
  default = "default"
}
