##### variables

variable "aws_region" {
  description = "AWS region."
  type = "string"
}

variable "aws_access_key" {
  description = "AWS access key."
  type = "string"
}

variable "aws_secret_key" {
  description = "AWS secret key."
  type = "string"
}

variable "win_admin_password" {
  description = "Windows admin password."
  type = "string"
}

variable "kali_user_password" {
  description = "Password for users on Kali boxes."
  type = "string"
}

variable "ssh_public_key" {
  description = "public SSH key for admin on all boxes."
  type = "string"
}

variable "ssh_private_key" {
  description = "private SSH key for admin on all boxes."
  type = "string"
}

variable "num_boxes" {
  description = "Number of kali-windows pairs to generate."
  type = "string"
  default = 1
}

##### output

output "all_the_ips" {
  value = "${formatlist("kali ext, kali int, win ext, win int: %s, %s, %s, %s", 
  	aws_instance.kali.*.public_ip,
    aws_instance.kali.*.private_ip,
    aws_instance.win2k8.*.public_ip,
    aws_instance.win2k8.*.private_ip)}"
}

# output "connect_cmd" {
#   value = "rdesktop -g 1600x900 -u Administrator -x l ${aws_instance.purgenol_win2k8r2.public_ip}"
# }

##### providers

provider "aws" {
	region = "us-east-1"
	access_key = "${var.aws_access_key}"
	secret_key = "${var.aws_secret_key}"
}

# http://jen20.com/2015/04/02/windows-amis-without-the-tears.html
# https://codex.org/2016/11/building-a-windows-2012r2-instance-in-aws-with-terraform/
# https://docs.aws.amazon.com/AWSEC2/latest/WindowsGuide/ec2-windows-passwords.html?icmpid=docs_ec2_console#ResettingAdminPassword
resource "aws_instance" "win2k8" {
	# ami-39ed8150  # WIndows 2008 R2 SP1 Clean
	# ami-51963c47
	# ami-ea75ad83  # Windows_Server-2008-R2-SP1-English-64Bit-WebMatrix_Development-2012.04.16
	# Amazon/Windows_Server-2008-R2_SP1-English-64Bit-Base-2015.01.02	ami-1e542176
	# Amazon/Windows_Server-2008-R2_SP1-English-64Bit-Base-2015.01.06	ami-bc5522d4
	# amazon/Windows_Server-2008-R2_SP1-English-64Bit-Base-2015.01.10	ami-b42959dc
	# amazon/Windows_Server-2008-R2_SP1-English-64Bit-Base-2015.01.16	ami-c4a5d9ac
	# Amazon/Windows_Server-2008-R2_SP1-English-64Bit-Base-2015.01.29	ami-86682fee
	# Amazon/Windows_Server-2008-R2_SP2-English-64Bit-Base-2015.01.01	ami-f6f79d9e
	# Amazon/Windows_Server-2008-R2_SP2-English-64Bit-Base-2015.01.04	ami-ac7602c4
	# Administrator:H@xdemo

	count = "${var.num_boxes}"
	ami = "ami-d7aaf2ac" # based on ami-1e542176
	instance_type = "t2.medium"
	vpc_security_group_ids = ["${aws_security_group.haxdemo_win2k8.id}"]
	subnet_id = "${aws_subnet.haxdemo_subnet.id}"
	key_name = "${aws_key_pair.haxdemo_key.id}"
	tags {
		Name = "HAXDEMO_WIN2K8_${count.index}"
	}

	# https://www.terraform.io/docs/provisioners/connection.html
	# https://github.com/dhoer/terraform_examples/blob/master/aws-winrm-instance/main.tf
	# connection {
	# 	type     = "winrm"
	# 	user     = "Administrator"
	# 	password = "${var.win_admin_password}"
	# }

	private_ip = "10.0.0.${count.index + 110}"

	user_data = <<EOF
		<powershell>
			net user Administrator "${var.win_admin_password}"
			$addy = "define('WP_HOME','http://aws_instance.win2k8.${count.index}.public_ip/wp46');define('WP_SITEURL','http://aws_instance.win2k8.${count.index}.public_ip/wp46');"
			$addy | Add-Content c:\www\wp46\wp-config.php
		</powershell>
	EOF

}

# https://aws.amazon.com/marketplace/fulfillment?productId=8b7fdfe3-8cd5-43cc-8e5e-4e0e7f4139d5&ref_=dtl_psb_continue&region=us-east-1
resource "aws_instance" "kali" {
	# username: haxdemo
	# kali 2018.1
	ami = "ami-10e00b6d"
	instance_type = "t2.small"
	vpc_security_group_ids = ["${aws_security_group.haxdemo_kali.id}"]
	subnet_id = "${aws_subnet.haxdemo_subnet.id}"
	private_ip = "10.0.0.${count.index + 10}"
	count = "${var.num_boxes}"
	key_name = "${aws_key_pair.haxdemo_key.id}"
	# private_ip = "10.0.1.${lookup(var.private_ips, count.index) + 10}"

	tags {
		Name = "HAXDEMO_KALI_${count.index}"
	}

  connection {
    type = "ssh"
    user = "ec2-user"
    private_key = "${file("${var.ssh_private_key}")}"
  }

  provisioner "remote-exec" {
    inline = [
      # "sudo su",
      "(echo \"${var.kali_user_password}\"; echo \"${var.kali_user_password}\") | sudo passwd ec2-user",
      "sudo apt install ftp -y",
      "sudo sed -i '1s@^@covfefeinthemorning\\n@' /usr/share/wordlists/rockyou.txt",
      "sudo sed -i '/PasswordAuthentication/d' /etc/ssh/sshd_config",
      # "useradd haxdemo",
      # "(echo \"${var.kali_user_password}\"; echo \"${var.kali_user_password}\") | passwd haxdemo",
      "sudo bash -c \"echo \"PasswordAuthentication yes\" >> /etc/ssh/sshd_config\"",
      "sudo systemctl restart sshd"
    ]
  }
}

# https://www.terraform.io/docs/providers/aws/r/vpc.html
resource "aws_vpc" "haxdemo_vpc" {
	cidr_block       = "10.0.0.0/24"
	instance_tenancy = "default"

	tags {
		Name = "haxdemo_vpc"
	}
}

resource "aws_key_pair" "haxdemo_key" {
	key_name   = "haxdemo_key"
	public_key = "${file("${var.ssh_public_key}")}"
}

# https://www.terraform.io/docs/providers/aws/r/internet_gateway.html
resource "aws_internet_gateway" "haxdemo_ig" {
	vpc_id = "${aws_vpc.haxdemo_vpc.id}"
}

# https://www.terraform.io/docs/providers/aws/r/default_security_group.html
resource "aws_security_group" "haxdemo_win2k8" {
	name = "haxdemo_win2k8"
	description = "haxdemo_win2k8"
	vpc_id = "${aws_vpc.haxdemo_vpc.id}"

	ingress {
		from_port = 3389
		to_port = 3389
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}

	ingress {
		from_port = 80
		to_port = 80
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}

	ingress {
		from_port = 0
		to_port = 0
		protocol = -1
		cidr_blocks = ["10.0.0.0/24"]
	}

	egress {
		from_port = 0
		to_port = 0
		protocol = -1
		cidr_blocks = ["10.0.0.0/24"]
	}

}

resource "aws_security_group" "haxdemo_kali" {
	name = "haxdemo_kali"
	description = "haxdemo_kali"
	vpc_id = "${aws_vpc.haxdemo_vpc.id}"
	ingress {
		from_port = 22
		to_port = 22
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}

	ingress {
		from_port = 0
		to_port = 0
		protocol = -1
		cidr_blocks = ["10.0.0.0/24"]
	}

	ingress {
		from_port = 3389
		to_port = 3389
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}	

	egress {
		from_port = 0
		to_port = 0
		protocol = -1
		cidr_blocks = ["0.0.0.0/0"]
	}
}

# https://www.terraform.io/docs/providers/aws/d/subnet.html
resource "aws_subnet" "haxdemo_subnet" {
	vpc_id = "${aws_vpc.haxdemo_vpc.id}"
	cidr_block = "10.0.0.0/24"
	map_public_ip_on_launch = true
}

resource "aws_route" "internet_access" {
	route_table_id = "${aws_vpc.haxdemo_vpc.main_route_table_id}"
	gateway_id = "${aws_internet_gateway.haxdemo_ig.id}"
	destination_cidr_block = "0.0.0.0/0"
}
