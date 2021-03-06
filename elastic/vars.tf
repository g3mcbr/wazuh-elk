variable "AWS_REGION" {
  default = "us-east-1"
}

variable "app_name" {
  type = "string"
  default = "elasticsearch"
}

variable "app_env" {
  type = "string"
  default = "test"
}

#variable "cluster" {
#  type = "string"
#  default = "ecs_elk-test-elastic"
#}

variable "desired_count" {
  type = "string"
  default = "3"
}

variable "volume_name" {
  type = "string"
  default = "elastic-container-vol"
}

variable "volume_host_path" {
  type = "string"
  default = "/data"
}

variable "container_name" {
  type = "string"
  default = "elasticsearch"
}

variable "container_port" {
  type = "string"
  default = "9200"
}

#variable "internal_nlb_name" {
#  type = "string"
#  default = "elk-test-internal-nlb"
#}

#######################################
variable "vpc_remote_state_bucket" {
  default = "tf-up-and-running-state"
}

variable "vpc_remote_state_key" {
  default = "dev/elktest/vpc/terraform.tfstate"
}

variable "cluster_remote_state_bucket" {
  default = "tf-up-and-running-state"
}

variable "cluster_remote_state_key" {
  default = "dev/elktest/cluster/terraform.tfstate"
}
