# /elknetwork/main.tf

provider "aws" {
    region = "${var.AWS_REGION}"
}


#module "vpc" {
#  source    = "github.com/silinternational/terraform-modules//aws/vpc?ref=2.0.2"
#  app_name  = "${var.app_name}"
#  app_env   = "${var.app_env}"
#  aws_zones = "${var.aws_zones}"
#}

module "vpc" {
  source                            = "../modules/network/vpc-with-nat-instance"
  app_name                          = "${var.app_name}"
  app_env                           = "${var.app_env}"
  aws_zones                         = "${var.aws_zones}"
  key_name                          = "${var.key_name}"
#  ecsTaskRoleAssumeRolePolicy       = "${var.ecsTaskRoleAssumeRolePolicy}"
#  ecsTaskRolePolicy                 = "${var.ecsTaskRolePolicy}"
  src_ips                           = "${var.src_ips}"
  nat_sg_ids                        = ["${module.vpc.vpc_default_sg_id}","${aws_security_group.allow-ssh.id}"]
}


module "ecscluster_es" {
  source                             = "github.com/silinternational/terraform-modules//aws/ecs/cluster"
  app_name                           = "${var.es_cluster_name}-${var.app_name}"
  app_env                            = "${var.app_env}"
  ecsInstanceRoleAssumeRolePolicy    = "${var.ecsInstanceRoleAssumeRolePolicy}"
  ecsInstancerolePolicy              = "${var.ecsInstancerolePolicy}"
}

module "ecscluster_lk" {
  source                             = "github.com/silinternational/terraform-modules//aws/ecs/cluster"
  app_name                           = "${var.lk_cluster_name}-${var.app_name}"
  app_env                            = "${var.app_env}"
  ecsInstanceRoleAssumeRolePolicy    = "${var.ecsInstanceRoleAssumeRolePolicy}"
  ecsInstancerolePolicy              = "${var.ecsInstancerolePolicy}"
}

module "external_elb" {
  source                    = "../modules/network/elb"
  app_name                  = "${var.app_name}"
  app_env                   = "${var.app_env}"
  elb_name                  = "${var.external_elb}"
  sg_groups                 = ["${module.vpc.vpc_default_sg_id}","${aws_security_group.ext-elb-inbound.id}"]
  subnets                   = "${module.vpc.public_subnet_ids}"
  internal                  = false
  listener                  = [
    {
      lb_port           = 80
      lb_protocol       = "http"
      instance_port     = 5601
      instance_protocol = "http"
    },
    {
      lb_port           = 1514
      lb_protocol       = "tcp"
      instance_port     = 1514
      instance_protocol = "tcp"
    },
    {
      lb_port           = 55000
      lb_protocol       = "tcp"
      instance_port     = 55000
      instance_protocol = "tcp"
    }
  ]
  health_check          = [
   {
      healthy_threshold   = 2
      unhealthy_threshold = 2
      timeout             = 3
      target              = "HTTP:5601/"
      interval            = 30
    }
  ]
}

module "elasticsearch_elb" {
  source                    = "../modules/network/elb"
  app_name                  = "${var.app_name}"
  app_env                   = "${var.app_env}"
  elb_name                  = "${var.elasticsearch_elb}"
  sg_groups                 = ["${module.vpc.vpc_default_sg_id}"]
  subnets                   = "${module.vpc.private_subnet_ids}"
  internal                  = true

  listener                  = [
    {
      lb_port           = 9200
      lb_protocol       = "http"
      instance_port     = 9200
      instance_protocol = "http"
    }
  ]
  health_check          = [
    {
      healthy_threshold   = 2
      unhealthy_threshold = 2
      target              = "HTTP:9200/"
      timeout             = 3
      interval            = 30
    }
  ]
}

module "logstash_elb" {
  source                    = "../modules/network/elb"
  app_name                  = "${var.app_name}"
  app_env                   = "${var.app_env}"
  elb_name                  = "${var.logstash_elb}"
  sg_groups                 = ["${module.vpc.vpc_default_sg_id}"]
  subnets                   = "${module.vpc.private_subnet_ids}"
  internal                  = true

  listener                  = [
    {
      lb_port           = 5000
      lb_protocol       = "tcp"
      instance_port     = 5000
      instance_protocol = "tcp"
    }
  ]
  health_check          = [
    {
      healthy_threshold   = 2
      unhealthy_threshold = 2
      target              = "TCP:5000"
      timeout             = 3
      interval            = 30
    }
  ]
}

# security group for external elb
resource "aws_security_group" "ext-elb-inbound" {
  vpc_id              = "${module.vpc.id}"
  name                = "${var.app_name}-${var.app_env}-ext-elb-inbound"
  description         = "security group that allows ${var.app_name} traffic to public elb"
  egress {
        from_port     = 0
        to_port       = 0
        protocol      = "-1"
        cidr_blocks   = ["0.0.0.0/0"]
  }
  ingress {
        from_port     = 80
        to_port       = 80
        protocol      = "tcp"
        cidr_blocks   = ["0.0.0.0/0"]
  }
  ingress {
        from_port     = 1514
        to_port       = 1514
        protocol      = "tcp"
        cidr_blocks   = ["76.177.144.62/32"]
  }
  ingress {
        from_port     = 55000
        to_port       = 55000
        protocol      = "tcp"
        cidr_blocks   = ["76.177.144.62/32"]
  }
  tags {
    Name              = "${var.app_name}-${var.app_env}-elb-inbound"
  }
}

resource "aws_security_group" "allow-ssh" {
  vpc_id = "${module.vpc.id}"
  name = "allow-ssh"
  description = "security group that allows ssh and all egress traffic"
  egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
      from_port = 22
      to_port = 22
      protocol = "tcp"
      cidr_blocks   = ["${var.src_ips}"]
  }
tags {
    Name = "allow-ssh"
  }
}

/*
 * Test creating a new task role.  Will move this later.
 */

resource "random_id" "code" {
   byte_length = 4
}

resource "aws_iam_role" "ecsTaskRole" {
   name               = "ecsTaskRole-${random_id.code.hex}"
   assume_role_policy = "${var.ecsTaskRoleAssumeRolePolicy}"
}

resource "aws_iam_role_policy" "ecsTaskRolePolicy" {
   name   = "ecsTaskRolePolicy-${random_id.code.hex}"
   role   = "${aws_iam_role.ecsTaskRole.id}"
   policy = "${var.ecsTaskRolePolicy}"
}




terraform {
  backend "s3" {
    bucket = "tf-up-and-running-state"
    key = "dev/elktest/vpc/terraform.tfstate"
    region = "us-east-1"
  }
}
