output "command_node_ip" {
  description = "Public IP of command node"
  value       = aws_instance.command_node.public_ip
}

output "scanner_node_ip" {
  description = "Public IP of scanner node"
  value       = aws_instance.scanner_node.public_ip
}

output "command_node_id" {
  description = "Instance ID of command node"
  value       = aws_instance.command_node.id
}

output "scanner_node_id" {
  description = "Instance ID of scanner node"
  value       = aws_instance.scanner_node.id
}