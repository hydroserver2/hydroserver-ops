output "self_hosted_tsdb_hostname" {
  value = aws_instance.primary_1.public_ip
}

