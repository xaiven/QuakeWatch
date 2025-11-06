output "server_public_ip" {
  value = aws_instance.server.public_ip
}

output "agent_public_ip" {
  value = aws_instance.agent.public_ip
}

output "ssh_server" {
  value = "ssh -i ~/.ssh/${var.project_name}.pem ubuntu@${aws_instance.server.public_ip}"
}
