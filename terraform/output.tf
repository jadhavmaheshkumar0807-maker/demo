output "public_ip_util_srv" {
    description = "Public IP of the util server"
    value = aws_instance.util_srv.public_ip
  
}

output "private_ip_util_srv" {
    description = "Public IP of the util server"
    value = aws_instance.util_srv.private_ip
  
}

output "public_ip_app_srv" {
    description = "Public IP of the app server"
    value = aws_instance.app_srv.public_ip
  
}

output "private_ip_app_srv" {
    description = "Public IP of the app server"
    value = aws_instance.app_srv.private_ip
  
}