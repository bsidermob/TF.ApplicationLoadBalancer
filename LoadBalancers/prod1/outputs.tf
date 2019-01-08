output "elb_dns_name" {
  value = "${module.loadbalancer.elb_dns_name}"
}

output "elb_zone_id" {
  value = "${module.loadbalancer.elb_zone_id}"
}
