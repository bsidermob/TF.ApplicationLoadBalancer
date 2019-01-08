provider "aws" {
  region                  = "ap-southeast-2"
  shared_credentials_file = "~/.aws/credentials"
  profile                 = "${terraform.workspace == "production" ? "AU-prod": "AU-non-prod"}"
}

module "loadbalancer" {
  source = "../../modules/loadbalancer"
  alb_suffix = "${var.alb_suffix}"
  sg_group_suffix = "${var.sg_group_suffix}"
  https_cert_arn_prod = "${var.https_cert_arn_prod}"
  https_cert_arn_non_prod = "${var.https_cert_arn_non_prod}"
}

module "dns" {
  source = "../../modules/dns_v2"
  elb_dns_name = "${module.loadbalancer.elb_dns_name}"
  services = "${var.services}"
  #elb_zone_id = "${module.loadbalancer.elb_zone_id}"
}
