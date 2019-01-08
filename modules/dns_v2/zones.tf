variable "route53_zone_ids_prod" {
  type    = "map"
  default = {
    "dummy.domain.name" = ""
  }
}

variable "route53_zone_ids_dev" {
  type    = "map"
  default = {
    "dummy.domain.name" = ""
  }
}
