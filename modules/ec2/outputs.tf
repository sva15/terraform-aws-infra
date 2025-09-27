# EC2 Module Outputs

output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.ui_server.id
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.ui_server.public_ip
}

output "instance_private_ip" {
  description = "Private IP address of the EC2 instance"
  value       = aws_instance.ui_server.private_ip
}

output "instance_public_dns" {
  description = "Public DNS name of the EC2 instance"
  value       = aws_instance.ui_server.public_dns
}

output "key_pair_name" {
  description = "Name of the key pair used for the EC2 instance"
  value       = var.create_key_pair ? aws_key_pair.ec2_key_pair[0].key_name : var.key_pair_name
}

output "private_key_filename" {
  description = "Filename of the private key (if created)"
  value       = var.create_key_pair ? "${local.key_pair_name}.pem" : null
  sensitive   = true
}

output "security_group_ids" {
  description = "Security group IDs attached to the instance"
  value       = var.security_group_ids
}
