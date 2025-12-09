#provider for terraform
provider "aws" {
    region = var.region
    profile = "default"
}

# creating VPC
resource "aws_vpc" "ammu_vpc" {
    cidr_block = var.vpc_cidr_block
    enable_dns_hostnames = true
    instance_tenancy = "default"
    tags = { Name = "ammu_vpc" }  
}

#creating subnet
resource "aws_subnet" "ammu_sn" {
    vpc_id = aws_vpc.ammu_vpc.id
    cidr_block = var.subnet_cidr_block
    availability_zone = var.availability_zone
    map_public_ip_on_launch = true
    tags = { Name = "ammu_sn" }  
}

#creating Internet Gateway
resource "aws_internet_gateway" "ammu_igw" {
    vpc_id = aws_vpc.ammu_vpc.id
    tags = { Name = "ammu_igw" }
}

#creating route table
resource "aws_route_table" "ammu_rt" {
    vpc_id = aws_vpc.ammu_vpc.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.ammu_igw.id
    }
}

# associating route table with subnet
resource "aws_route_table_association" "public_rta" {
    route_table_id = aws_route_table.ammu_rt.id
    subnet_id = aws_subnet.ammu_sn.id  
}

#security group for jenkins server
resource "aws_security_group" "util_srv_sg" {
    name = "util_srv_sg"
    description = "security group for jenkins server"
    vpc_id = aws_vpc.ammu_vpc.id

    ingress {
        description = "jenkins"
        from_port   = 8080
        to_port     = 8080
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

   
    ingress {
        description = "sonarqube"
        from_port = 9000
        to_port = 9000
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        description = "ssh"
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        description = "all outbound traffic"
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = { Name = "util_srv_sg" } 
}

#security group for util server
resource "aws_security_group" "app_srv_sg" {
    name = "app_srv_sg"
    description = "security group for util server"
    vpc_id = aws_vpc.ammu_vpc.id

    ingress {
        description = "app"
        from_port = 8080
        to_port = 8080
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        description = "ssh"
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        description = "all inbound traffic"
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        description = "all outbound traffic"
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = { Name = "app_srv_sg" } 
}

#creating jenkins instance
resource "aws_instance" "util_srv" {
    ami = var.aws_ami
    instance_type =  var.instance_type
    key_name = var.key_name
    subnet_id = aws_subnet.ammu_sn.id
    vpc_security_group_ids = [ aws_security_group.util_srv_sg.id ]
    root_block_device {
      volume_size = 25
      volume_type = "gp3"
      encrypted = true
    }
    
    connection {
      type = "ssh"
      user = "ec2-user"
      private_key = file("C:/Users/AravindJadhav/Desktop/keys/AWS-key.pem")
      host = self.public_ip
    }

    provisioner "remote-exec" {
        inline = [
      "sudo yum update -y",
      "sudo yum install wget git maven docker ansible -y",
      "sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo",
      "sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key",
      "sudo yum install jenkins -y",
      "sudo systemctl enable jenkins && sudo systemctl start jenkins",
      "sudo systemctl enable docker && sudo systemctl start docker",
      "sudo usermod -aG docker ec2-user",
      "sudo usermod -aG docker jenkins",
      "sudo chmod 666 /var/run/docker.sock",
      "sudo docker run -itd --name sonar -p 9000:9000 sonarqube",
      "curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sudo sh -s -- -b /usr/local/bin v0.68.1"
        ]
    }

    tags = { Name = "util_srv" }
  
}

# creating app server
resource "aws_instance" "app_srv" {
    ami = var.aws_ami
    instance_type = var.instance_type
    key_name = var.key_name
    subnet_id = aws_subnet.ammu_sn.id
    vpc_security_group_ids = [ aws_security_group.app_srv_sg.id ]
    root_block_device {
      volume_size = 25
      volume_type = "gp3"
      encrypted = true
    }
    
    connection {
      type = "ssh"
      user = "ec2-user"
      private_key = file("C:/Users/AravindJadhav/Desktop/keys/AWS-key.pem")
      host = self.public_ip
    }

    provisioner "remote-exec" {
  inline = [
    "sudo yum update -y",
    "curl -o kubectl https://s3.us-west-2.amazonaws.com/amazon-eks/1.34.2/2025-11-13/bin/linux/amd64/kubectl",
    "curl -o kubectl.sha256 https://s3.us-west-2.amazonaws.com/amazon-eks/1.34.2/2025-11-13/bin/linux/amd64/kubectl.sha256",
    "sha256sum -c kubectl.sha256",
    "chmod +x ./kubectl",
    "sudo mv ./kubectl /usr/local/bin/kubectl",
    "echo Installing eksctl",
    "curl --silent --location https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_Linux_amd64.tar.gz | tar xz -C /tmp",
    "sudo mv /tmp/eksctl /usr/local/bin",
    "echo Verify tools",
    "kubectl version --client",
    "eksctl version",
    "echo Installing Helm",
    "curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-4",
    "chmod 700 get_helm.sh",
    "./get_helm.sh"
  ]
}


    tags = { Name = "app-srv" }
  
}

