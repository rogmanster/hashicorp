resource "tls_private_key" "awskey" {
  algorithm = "RSA"
}

resource "null_resource" "awskey" {
  provisioner "local-exec" {
    command = "echo \"${tls_private_key.awskey.private_key_pem}\" > awskey.pem"
  }

  provisioner "local-exec" {
    command = "chmod 600 awskey.pem"
  }
}
