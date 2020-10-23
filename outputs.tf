# Print single public IP for jenkins master
output "Jenkins-Main-Node-Public-IP" {
  value = aws_instance.jenkins-master.public_ip
}

# Print all public IPs for jenkins workers
output "Jenkins-Worker-Public-IPs" {
  value = {
    for instance in aws_instance.jenkins-worker-oregon :
    instance.id => instance.public_ip
  }
}

# Print hostname of jenkins ALB
output "LB-DNS-NAME" {
  value = aws_lb.application-lb.dns_name
}

# Print alias record for ALB
output "url" {
  value = aws_route53_record.jenkins.fqdn
}
