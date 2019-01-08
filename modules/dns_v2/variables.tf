variable "regions" {
    type = "list"
    default = [
        "au"
    ]
}

variable "prefixes_dev" {
    type = "list"
    default = [
        "dev-",
        "sit-",
        "uat-"
    ]
}

variable "prefixes_prod" {
    type = "list"
    default = [
		""
    ]
}

variable "suffixes_dev" {
    type = "list"
    default = [
        "-partner"
    ]
}

variable "suffixes_prod" {
    type = "list"
    default = [
        "-partner"
    ]
}

variable "elb_dns_name" {}
#variable "elb_zone_id" {}
variable "services" {type = "list"}