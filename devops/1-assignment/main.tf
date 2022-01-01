terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.70.0"
    }
  }

}

provider "aws" {
  region = "us-east-1"
}


data "aws_ami" "tf_ami" {
  most_recent      = true
  owners           = ["self"]

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

}

resource "aws_instance" "tf-ec2" {

  ami = data.aws_ami.tf_ami.id
  instance_type = var.ec2_type
  key_name      = "firstkey" 
  count = 2
  security_groups = ["tf-sg2"]
  tags = {
    "Name" = "${var.ec2_name[count.index]}"
  }

  provisioner "local-exec" {
      command = "echo http://${self.public_ip} > public_ip.txt"
  }

  provisioner "local-exec" {
      command = "echo http://${self.private_ip} > private_ip.txt"
  }

  connection {
    host = self.public_ip
    type = "ssh"
    user = "ec2-user"
    private_key = file("firstkey.pem")
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y",
      "sudo yum -y install httpd",
      "sudo systemctl enable httpd",
      "sudo systemctl start httpd",
      "echo 'Hello World' > index.html",
      "sudo cp index.html /var/www/html/"
    ]
  }

/*   provisioner "file" {
    content = self.public_ip
    destination = "/home/ec2-user/my_public_ip.txt"
  }

  provisioner "file" {
    content = self.private_ip
    destination = "/home/ec2-user/my_private_ip.txt"
 } */

}



resource "aws_security_group" "tf-sec-gr" {
  name = "tf-sg2"
  tags = {
    Name = "tf-sg2"
  }

  ingress {
    from_port   = 80
    protocol    = "tcp"
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
      from_port = 22
      protocol = "tcp"
      to_port = 22
      cidr_blocks = [ "0.0.0.0/0" ]
  }

  egress {
      from_port = 0
      protocol = -1
      to_port = 0
      cidr_blocks = [ "0.0.0.0/0" ]
  }
}


variable "ec2_type" {
  default = "t2.micro"
}

variable "ec2_name" {
  default = ["Terraform First Instance", "Terraform Second Instance"]
}

output "instance_public_ip" {
  value = aws_instance.tf-ec2.*.public_ip

}

