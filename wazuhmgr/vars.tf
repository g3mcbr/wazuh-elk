variable "AWS_REGION" {
  default = "us-east-1"
}

variable "app_name" {
  type = "string"
  default = "wazuhmgr"
}

variable "app_env" {
  type = "string"
  default = "test"
}

variable "cluster" {
  type = "string"
  default = "ecs_elk-test-logstash"
}

variable "external_elb_name" {
  type = "string"
  default = "elk-test-external-elb"
}
variable "desired_count" {
  type = "string"
  default = "1"
}

variable "volume_name" {
  type = "string"
  default = "wazuh-slave-config"
}

variable "volume_host_path" {
  type = "string"
  default = "/wazuh/slave"
}

variable "container_name" {
  type = "string"
  default = "wazuhmgr"
}

variable "container_port" {
  type = "string"
  default = "1514"
}
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
