output "public_dns" {
  value = "${aws_instance.ubuntu.public_dns}"
}

output "public_ip" {
  value = "${aws_instance.ubuntu.public_ip}"
}
