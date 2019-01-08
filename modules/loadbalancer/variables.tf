### Configurable variables

variable "alb_suffix" {}

variable "sg_group_suffix" {}

variable "https_cert_arn_prod" {}

variable "https_cert_arn_non_prod" {}

### Fixed variables

variable "region" {
  default = "au"
}

variable "subnets_prod" {
  type    = "list"
  default = [""]
}

variable "subnets_non_prod" {
  type    = "list"
  default = [""]
}

variable "vpc_prod_id" {
  default = ""
}

variable "vpc_non_prod_id" {
  default = ""
}

# sg_prod_app
variable "sg_prod_app_id" {
  default = ""
}

# sg_nonprod_app
variable "sg_non_prod_app_id" {
  default = ""
}

# These are access groups used to access resources from office
variable "sg_non_prod_additional_groups" {
  type    = "list"
  default = [
    ""
  ]
}

variable "main_target_group_name" {
  default = "app1"
}

variable "websocket_target_group_name" {
  default = "websocket-app1"
}

variable "app_instance_id_prod" {
  default = ""
}

# au-npd-app1
variable "app_instance_id_non_prod" {
  default = ""
}

variable "nat_gateway_id_non_prod" {
  default = ""
}
