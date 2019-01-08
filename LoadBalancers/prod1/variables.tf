variable "services" {
    type = "list"
    default = [
		"partner1", "partner2"
    ]
}

variable "alb_suffix" {
  default = "1"
}

variable "sg_group_suffix" {
  default = "alb1"
}

### non-prod cert
variable "https_cert_arn_prod" {
  default = ""
}

### prod cert
variable "https_cert_arn_non_prod" {
  default = ""
}
