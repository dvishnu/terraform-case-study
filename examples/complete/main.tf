provider "aws" {
  access_key = "AKIAIYE4JUKCGBDWKTSQ"
  secret_key = "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"
  region     = "ap-south-1"
  version = "~> 1.7"
}

variable "number_of_instances" {
  description = "Number of instances to create and attach to ELB"
  default     = 2
}

##############################################################
# Data sources to get VPC Details , subnets and security group details
##############################################################
data "aws_vpc" "default" {
  default = true
}

data "aws_subnet_ids" "all" {
  vpc_id = "${data.aws_vpc.default.id}"
}

data "aws_security_group" "default" {
  vpc_id = "${data.aws_vpc.default.id}"
  name   = "default"
}

######
# ELB
######
module "elb" {
  source = "../../"

  name = "elb-example"

  subnets         = ["${data.aws_subnet_ids.all.ids}"]
  security_groups = ["${data.aws_security_group.default.id}"]
  internal        = false

  listener = [
    {
      instance_port     = "80"
      instance_protocol = "HTTP"
      lb_port           = "80"
      lb_protocol       = "HTTP"
    },
    {
      instance_port     = "8080"
      instance_protocol = "HTTP"
      lb_port           = "8080"
      lb_protocol       = "HTTP"
    },
  ]

  health_check = [
    {
      target              = "HTTP:80/"
      interval            = 30
      healthy_threshold   = 2
      unhealthy_threshold = 2
      timeout             = 5
    },
  ]

  // Uncomment this section and set correct bucket name to enable access logging
  //  access_logs = [
  //    {
  //      bucket = "my-access-logs-bucket"
  //    },
  //  ]

  tags = {
    Owner       = "user"
    Environment = "dev"
  }
  # ELB attachments
  number_of_instances = "${var.number_of_instances}"
  instances           = ["${module.ec2_instances.id}"]
}

################
# EC2 instances
################
module "ec2_instances" {
  source = "terraform-aws-modules/ec2-instance/aws"

  instance_count = "${var.number_of_instances}"

  name                        = "my-app"
  ami                         = "ami-0912f71e06545ad88"
  instance_type               = "t2.micro"
  vpc_security_group_ids      = ["sg-09442df2f89196640"]
  subnet_id                   = "${var.subnet_id}"
  associate_public_ip_address = true
  key_name = "vardhan231"
  user_data = <<EOF
              #!/bin/bash
              yum remove php*
              #Update Reposistory
              rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-6.noarch.rpm
              rpm -Uvh https://mirror.webtatic.com/yum/el6/latest.rpm
              #Update Amaxon AMI
              yum upgrade -y
              #Install PHP
              #List of PHP packages https://webtatic.com/packages/php71/
              yum install php71w install php71w-cli  php71w-fpm -y
              yum install php71w-mysql  php71w-xml php71w-curl -y
              yum install php71w-opcache php71w-pdo php71w-gd -y
              yum install php71w-pecl-apcu php71w-mbstring php71w-imap -y
              yum install php71w-pecl-redis php71w-mcrypt -y
              yum install mysql mysql-server httpd -y
              #yum install httpd php php-mysql php-xcache  php-gd php-xml mysql mysql-server wget -y
              chkconfig httpd on
              chkconfig mysqld on
              cd /home/ec2-user
              wget "https://releases.wikimedia.org/mediawiki/1.31/mediawiki-1.31.1.tar.gz"
              tar -xvzf mediawiki-1.31.1.tar.gz
              cp -R mediawiki-1.31.1/* /var/www/html
              service httpd restart
              EOF

}
##db##
resource "aws_db_instance" "testdb" {
  engine         = "mysql"
  engine_version = "5.7.19"
  allocated_storage = 20
  instance_class = "db.t2.micro"
  name           = "mydb1"
  username       = "mydb1"
  password       = "${var.password}"
  publicly_accessible      = true


  # etc, etc; see aws_db_instance docs for more
}
resource "aws_security_group" "mydb1" {
  name = "mydb1"

  description = "RDS Mysql servers (terraform-managed)"
  vpc_id = "${var.rds_vpc_id}"

  # Only Mysql in
  ingress {
    from_port = 3306
    to_port = 3306
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic.
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
