# output "ip_public_kali" {
#   value = ["${aws_instance.kali.*.public_ip}"]
# }

output "ips_kali" {
  value = "${zipmap(
    aws_instance.kali.*.public_ip,
    aws_instance.kali.*.private_ip
  )}"
}

output "ips_win2k8" {
  value = "${zipmap(
    aws_instance.win2k8.*.public_ip,
    aws_instance.win2k8.*.private_ip
  )}"
}
