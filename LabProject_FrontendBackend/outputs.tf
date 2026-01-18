output "frontend_public_ip" {
  value       = aws_instance.frontend.public_ip
  description = "Public IP of frontend server"
}

output "backend_public_ips" {
  value       = [for b in aws_instance.backend : b.public_ip]
  description = "Public IPs of backend servers"
}

output "backend_private_ips" {
  value       = [for b in aws_instance.backend : b.private_ip]
  description = "Private IPs of backend servers"
}

output "test_url" {
  value       = "http://${aws_instance.frontend.public_ip}"
  description = "URL to test the load balancer"
}

output "ssh_commands" {
  value = {
    frontend  = "ssh -i ~/.ssh/terraform_key ec2-user@${aws_instance.frontend.public_ip}"
    backend_0 = "ssh -i ~/.ssh/terraform_key ec2-user@${aws_instance.backend[0].public_ip}"
    backend_1 = "ssh -i ~/.ssh/terraform_key ec2-user@${aws_instance.backend[1].public_ip}"
    backend_2 = "ssh -i ~/.ssh/terraform_key ec2-user@${aws_instance.backend[2].public_ip}"
  }
  description = "SSH commands to connect to instances"
}
