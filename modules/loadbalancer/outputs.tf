output "elb_dns_name" {
  value = "${data.aws_lb.alb.dns_name}"
}

output "elb_zone_id" {
  value = "${data.aws_lb.alb.zone_id}"
}