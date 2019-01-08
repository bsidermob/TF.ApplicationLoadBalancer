resource "aws_lb" "alb" {
  name               = "${terraform.workspace == "production" ? format("%s%s", "alb-${var.region}-prod", var.alb_suffix) :  format("%s%s", "alb-${var.region}-nonprod" , var.alb_suffix)}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["${split(",", terraform.workspace == "production" ? join(",", list(aws_security_group.sg.id)) : join(",", concat(var.sg_non_prod_additional_groups, list(aws_security_group.sg.id))))}"]
  subnets            = ["${split(",", terraform.workspace == "production" ? join(",", var.subnets_prod) : join(",",var.subnets_non_prod))}"]

  access_logs {
    bucket  = "${aws_s3_bucket.lb_logs.bucket}"
    enabled = true
  }

  tags = {
        "Environment" = "Production"
        "Business Unit" = "Technology"
        "Name" = "${terraform.workspace == "production" ? format("%s%s", "alb-${var.region}-prod", var.alb_suffix) :  format("%s%s", "alb-${var.region}-nonprod" , var.alb_suffix)}"
        "InUse" = "True"
  }

  enable_deletion_protection = true
  depends_on = ["aws_s3_bucket_policy.lb_logs_policy"]
}

resource "aws_lb_listener" "front_end_http" {
  load_balancer_arn = "${aws_lb.alb.arn}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${aws_lb_target_group.main.arn}"
    type             = "forward"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# HTTPS listener
resource "aws_lb_listener" "front_end_https" {
  load_balancer_arn = "${aws_lb.alb.arn}"
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2015-05"
  certificate_arn   = "${terraform.workspace == "production" ? var.https_cert_arn_prod :  var.https_cert_arn_non_prod}"

  default_action {
    target_group_arn = "${aws_lb_target_group.main.arn}"
    type             = "forward"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener_rule" "websockets" {
  listener_arn = "${aws_lb_listener.front_end_https.arn}"
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.websocket.arn}"
  }

  condition {
    field  = "path-pattern"
    values = ["/signalr"]
  }
}

resource "aws_lb_target_group" "main" {
  name     = "${terraform.workspace == "production" ? format("%s%s", "${var.region}-prod-", var.main_target_group_name) :  format("%s%s", "${var.region}-nonprod-" , var.main_target_group_name)}"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "${terraform.workspace == "production" ? var.vpc_prod_id :  var.vpc_non_prod_id}"

  health_check {
    healthy_threshold = "5"
    unhealthy_threshold = "2"
    path = "/health.html"
    interval = "30"
    matcher = "200"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# This is required to make websockets work as they need sticky cookies

resource "aws_lb_target_group" "websocket" {
  name     = "${terraform.workspace == "production" ? format("%s%s", "${var.region}-prod-", var.websocket_target_group_name) :  format("%s%s", "${var.region}-nonprod-" , var.websocket_target_group_name)}"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "${terraform.workspace == "production" ? var.vpc_prod_id :  var.vpc_non_prod_id}"

  stickiness {
    type = "lb_cookie"
    cookie_duration = "86400"
  }

  health_check {
    healthy_threshold = "5"
    unhealthy_threshold = "2"
    path = "/health.html"
    interval = "30"
    matcher = "200"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_target_group_attachment" "main" {
  target_group_arn = "${aws_lb_target_group.main.arn}"
  target_id        = "${terraform.workspace == "production" ? var.app_instance_id_prod :  var.app_instance_id_non_prod}"
  port             = 80
}

resource "aws_lb_target_group_attachment" "websocket" {
  target_group_arn = "${aws_lb_target_group.websocket.arn}"
  target_id        = "${terraform.workspace == "production" ? var.app_instance_id_prod :  var.app_instance_id_non_prod}"
  port             = 80
}

resource "aws_security_group" "sg" {
  name        = "${terraform.workspace == "production" ? format("%s%s", "sg_prod_${var.region}_", var.sg_group_suffix) :  format("%s%s", "sg_nonprod_${var.region}_" , var.sg_group_suffix)}"
  description = "Allow all HTTP & HTTPS inbound traffic"
  vpc_id      = "${terraform.workspace == "production" ? var.vpc_prod_id :  var.vpc_non_prod_id}"

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "elb_in_http" {
  type            = "ingress"
  from_port       = 80
  to_port         = 80
  protocol        = "tcp"
  source_security_group_id = "${aws_security_group.sg.id}"
  security_group_id = "${terraform.workspace == "production" ? var.sg_prod_app_id :  var.sg_non_prod_app_id}"
}

resource "aws_security_group_rule" "elb_in_https" {
  type            = "ingress"
  from_port       = 443
  to_port         = 443
  protocol        = "tcp"
  source_security_group_id = "${aws_security_group.sg.id}"
  security_group_id = "${terraform.workspace == "production" ? var.sg_prod_app_id :  var.sg_non_prod_app_id}"
}

# This adds 0.0.0.0 access rule for the public LB in prod environment

resource "aws_security_group_rule" "elb_ext_in_http" {
  count = "${terraform.workspace == "production" ? 1 : 0}"
  type            = "ingress"
  from_port       = 80
  to_port         = 80
  protocol        = "tcp"
  cidr_blocks     = ["0.0.0.0/0"]
  ipv6_cidr_blocks = ["::/0"]
  security_group_id = "${aws_security_group.sg.id}"
}


resource "aws_security_group_rule" "elb_in_ext_https" {
  count = "${terraform.workspace == "production" ? 1 : 0}"
  type            = "ingress"
  from_port       = 443
  to_port         = 443
  protocol        = "tcp"
  cidr_blocks     = ["0.0.0.0/0"]
  ipv6_cidr_blocks = ["::/0"]
  security_group_id = "${aws_security_group.sg.id}"
}

# This adds app servers to access rule for the public LB in DEV environment

resource "aws_security_group_rule" "elb_ext_dev_in_http" {
  count = "${terraform.workspace == "production" ? 0 : 1}"
  type            = "ingress"
  from_port       = 80
  to_port         = 80
  protocol        = "tcp"
  cidr_blocks     = ["${format("%s%s", "${data.aws_nat_gateway.main.public_ip}", "/32")}"]
  security_group_id = "${aws_security_group.sg.id}"
}


resource "aws_security_group_rule" "elb_in_dev_ext_https" {
  count = "${terraform.workspace == "production" ? 0 : 1}"
  type            = "ingress"
  from_port       = 443
  to_port         = 443
  protocol        = "tcp"
  cidr_blocks     = ["${format("%s%s", "${data.aws_nat_gateway.main.public_ip}", "/32")}"]
  security_group_id = "${aws_security_group.sg.id}"
}

### S3 bucket for logs
resource "aws_s3_bucket" "lb_logs" {
  bucket = "${terraform.workspace == "production" ? format("%s%s", "bsidermob-logs-alb-${var.region}-prod", lower(var.alb_suffix)) :  format("%s%s", "bsidermob-logs-alb-${var.region}-nonprod" , lower(var.alb_suffix))}"
  acl    = "private"

  lifecycle_rule {
    id      = "log_rotation_3_months"
    enabled = true

    expiration {
      days = 90
    }
  }
}

# This policy enables AWS ELB/ALB access to S3 bucket

resource "aws_s3_bucket_policy" "lb_logs_policy" {
  bucket = "${aws_s3_bucket.lb_logs.id}"
  policy =<<POLICY
{
    "Version": "2012-10-17",
    "Id": "AWSConsole-AccessLogs-Policy-1505435486676",
    "Statement": [
        {
            "Sid": "AWSConsoleStmt-1505435486676",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::783225319266:root"
            },
            "Action": "s3:PutObject",
            "Resource": "${aws_s3_bucket.lb_logs.arn}/*"
        }
    ]
}
POLICY
}

resource "null_resource" "update_dns_dictionary" {
  provisioner "local-exec" {
    command = "export elb_dns_name=${data.aws_lb.alb.dns_name} && python ../../modules/dns/update-dns-dictionary.py"
  }
}

### Data

data "aws_instance" "app1" {
  instance_id = "${terraform.workspace == "production" ? var.app_instance_id_prod :  var.app_instance_id_non_prod}"
}

data "aws_lb" "alb" {
  arn  = "${aws_lb.alb.id}"
}

data "aws_nat_gateway" "main" {
  count = "${terraform.workspace == "production" ? 0 : 1}"
  id = "${var.nat_gateway_id_non_prod}"
}
