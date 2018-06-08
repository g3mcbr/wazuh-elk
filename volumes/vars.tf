variable "AWS_REGION" {
  default = "us-east-1"
}

variable "vpc_remote_state_bucket" {
  default = "tf-up-and-running-state"
}

variable "vpc_remote_state_key" {
  default = "dev/elktest/vpc/terraform.tfstate"
}

variable "volume_type" {
  default = "standard"
}
