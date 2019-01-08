### This updates DNS records in Route53
###

### Make sure to switch to the right credential set below

provider "aws" {
  region                  = "ap-southeast-2"
  shared_credentials_file = "~/.aws/credentials"
  profile                 = "AU-prod"
}

### White Label partner URL
### Dev
# AU
# make sure to change dummy.domain.name to something else 

resource "aws_route53_record" "non-prod-au" {
	count   = "${length(var.prefixes_dev) * length(var.services) * length(var.suffixes_dev) * (terraform.workspace == "non-production" ? 1 : 0)}"
	zone_id = "${lookup(var.route53_zone_ids_prod, "dummy.domain.name")}"
	name    = "${element(formatlist("%s%s%s",
				  var.prefixes_dev,
				  element(var.services, count.index),
				  element(var.suffixes_dev, count.index)
				), count.index)}"
	type    = "CNAME"
	ttl     = "300"
	records = ["${var.elb_dns_name}"]
}


### Prod
# AU
resource "aws_route53_record" "prod-au" {
	count   = "${length(var.prefixes_prod) * length(var.services) * length(var.suffixes_prod) * (terraform.workspace == "production" ? 1 : 0)}"
	zone_id = "${lookup(var.route53_zone_ids_prod, "dummy.domain.name")}"
	name    = "${element(formatlist("%s%s%s",
				  var.prefixes_prod,
				  element(var.services, count.index),
				  element(var.suffixes_prod, count.index)
				), count.index)}"
	type    = "CNAME"
	ttl     = "300"
	records = ["${var.elb_dns_name}"]
}
