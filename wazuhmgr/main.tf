# /wazuh/main.tf

provider "aws" {
    region = "${var.AWS_REGION}"
}

data "terraform_remote_state" "newvpc" {
  backend = "s3"

  config {
    bucket = "${var.vpc_remote_state_bucket}"
    key    = "${var.vpc_remote_state_key}"
    region = "${var.AWS_REGION}"
  }
}

data "terraform_remote_state" "cluster" {
  backend = "s3"

  config {
    bucket = "${var.cluster_remote_state_bucket}"
    key    = "${var.cluster_remote_state_key}"
    region = "${var.AWS_REGION}"
  }
}

data "null_data_source" "logstash_cluster_ips"{
  inputs = {
    cluster_ips = "${join(" ",  data.terraform_remote_state.cluster.logstash_ecs_host_ips)}"
  }
}

data "template_file" "task_def" {
  template = "${file("${path.module}/task_def_wazuhmgr.json")}"
  vars {
  logstash_node  = "${data.terraform_remote_state.newvpc.logstash_elb_dns_name}"
#  cluster_ip1         = "${element("${data.terraform_remote_state.cluster.logstash_ecs_host_ips}", 0)}"
#  cluster_ip2         = "${element("${data.terraform_remote_state.cluster.logstash_ecs_host_ips}", 1)}"
  cluster_ips         = "${data.null_data_source.logstash_cluster_ips.outputs.cluster_ips}"
  }
}

module "wazuhmgr1" {
  source                    = "../modules/services/with-elb-and-volume"
  app_name                  = "${var.app_name}1"
  app_env                   = "${var.app_env}"
  cluster                   = "${data.terraform_remote_state.newvpc.lk_cluster_id}"
#  target_group_arn          = "${data.terraform_remote_state.loadbalancers.wazuh_mgr_target_group_arn}"
  elb_name                  = "${data.terraform_remote_state.newvpc.external_elb_name}"
  container_def_json        = "${data.template_file.task_def.rendered}"
  task_role_arn             = "${data.terraform_remote_state.newvpc.ecsTaskRole_arn}"
  desired_count             = "${var.desired_count}"
  volume_name               = "${var.volume_name}"
  volume_host_path          = "${var.volume_host_path}1"
  container_name            = "${var.container_name}"
  container_port            = "${var.container_port}"
}

module "wazuhmgr2" {
  source                    = "../modules/services/with-elb-and-volume"
  app_name                  = "${var.app_name}2"
  app_env                   = "${var.app_env}"
  cluster                   = "${data.terraform_remote_state.newvpc.lk_cluster_id}"
#  target_group_arn          = "${data.terraform_remote_state.loadbalancers.wazuh_mgr_target_group_arn}"
  elb_name                  = "${data.terraform_remote_state.newvpc.external_elb_name}"
  container_def_json        = "${data.template_file.task_def.rendered}"
  task_role_arn             = "${data.terraform_remote_state.newvpc.ecsTaskRole_arn}"
  desired_count             = "${var.desired_count}"
  volume_name               = "${var.volume_name}"
  volume_host_path          = "${var.volume_host_path}2"
  container_name            = "${var.container_name}"
  container_port            = "${var.container_port}"
}

terraform {
  backend "s3" {
    bucket = "tf-up-and-running-state"
    key = "dev/elktest/wazuhmgr/terraform.tfstate"
    region = "us-east-1"
  }
}
