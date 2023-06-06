variable "instance_name" {
  description = "Value of the Name tag for the EC2 instance"
  type        = string
  default     = "ExampleAppServerInstance"
}

variable "domain_name" {
  default = "iconic.fun"
}

variable "project_name" {
  default = "swap-dev"
}

variable "env" {
  default = "dev"
}

variable "certificate_arn" {
  default = ""
}