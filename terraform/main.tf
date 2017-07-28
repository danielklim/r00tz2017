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
	count = 2

	ami = "ami-1484da6f" # based on ami-1e542176
	instance_type = "t2.medium"
	vpc_security_group_ids = ["${aws_security_group.haxdemo_win2k8.id}"]
	subnet_id = "${aws_subnet.haxdemo_subnet.id}"
	key_name = "${aws_key_pair.haxdemo_key.id}"
	tags {
		Name = "HAXDEMO_WIN2K8_${count.index}"
	}

	# https://www.terraform.io/docs/provisioners/connection.html
	# https://github.com/dhoer/terraform_examples/blob/master/aws-winrm-instance/main.tf
	connection {
		type     = "winrm"
		user     = "Administrator"
		password = "${var.admin_password}"
	}

	private_ip = "10.0.0.${count.index + 110}"

# # Configure a Windows host for remote management (this works for both Ansible and Chef)
# # You will want to copy this script to a location you own (e.g. s3 bucket) or paste it here
# Invoke-Expression ((New-Object System.Net.Webclient).DownloadString('https://raw.githubusercontent.com/ansible/ansible/devel/examples/scripts/ConfigureRemotingForAnsible.ps1'))
# # Set Administrator password
# $admin = [adsi]("WinNT://./administrator, user")
# $admin.psbase.invoke("SetPassword", "${var.admin_password}")
	user_data = <<EOF
<powershell>
	$addy = "define('WP_HOME','http://10.0.0.${count.index + 110}/wp46');define('WP_SITEURL','http://10.0.0.${count.index + 110}/wp46');"
	$addy | Add-Content c:\www\wp46\wp-config.php
</powershell>
EOF
}

# https://aws.amazon.com/marketplace/fulfillment?productId=8b7fdfe3-8cd5-43cc-8e5e-4e0e7f4139d5&ref_=dtl_psb_continue&region=us-east-1
resource "aws_instance" "kali" {
	count = 2
	# haxdemo:CorrectBatteryHorseStaple
	# ami = "ami-5008d946"
	# ami = "ami-b2e4aca4"
	ami = "ami-f4227c8f"
	instance_type = "t2.medium"
	vpc_security_group_ids = ["${aws_security_group.haxdemo_kali.id}"]
	subnet_id = "${aws_subnet.haxdemo_subnet.id}"
	# key_name = "${aws_key_pair.haxdemo_key.id}"
	# https://blog.gruntwork.io/an-introduction-to-terraform-f17df9c6d180
	# user_data = <<-EOF
	#           #!/bin/bash
	#           echo "Hello, World" > index.html
	#           nohup busybox httpd -f -p 8080 &
	#           EOF
	private_ip = "10.0.0.${count.index + 10}"
	# private_ip = "10.0.1.${lookup(var.private_ips, count.index) + 10}"
	# element(aws_subnet.foo.*.id, count.index)

	tags {
		Name = "HAXDEMO_KALI_${count.index}"
	}

	# connection {
	# 	type = "ssh"
	# 	user = "ec2-user"
	# 	# https://github.com/hashicorp/terraform/issues/9308
	# 	private_key = "${file("ssh/haxdemo.pem")}"
	# 	# password = "${var.root_password}"
	# }

	# provisioner "file" {
	# 	source      = "script.sh"
	# 	destination = "/tmp/script.sh"
	# }

	# provisioner "remote-exec" {
	# 	inline = [
	# 		# "chmod +x /tmp/script.sh",
	# 		"sudo msfupdate",
	# 		"sudo apt install ftp -y",
	# 	]
	# }
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
	public_key = "${file("ssh/executor.pub")}"
}

# https://www.terraform.io/docs/providers/aws/r/internet_gateway.html
resource "aws_internet_gateway" "haxdemo_ig" {
	vpc_id = "${aws_vpc.haxdemo_vpc.id}"
}

# https://www.terraform.io/docs/providers/aws/d/security_group.html
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
		from_port = 0
		to_port = 0
		protocol = -1
		cidr_blocks = ["10.0.0.0/24"]
	}

	egress {
		from_port = 0
		to_port = 0
		protocol = -1
		cidr_blocks = ["0.0.0.0/0"]
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
	route_table_id         = "${aws_vpc.haxdemo_vpc.main_route_table_id}"
	gateway_id             = "${aws_internet_gateway.haxdemo_ig.id}"
	destination_cidr_block = "0.0.0.0/0"
}
