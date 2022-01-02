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

resource "aws_instance" "tf-ec2" {
  ami             = "ami-0ed9277fb7eb570c9"
  instance_type   = "t2.micro"
  key_name        = "firstkey"  # your key pem file name
  security_groups = ["tf-kittens-sg"]


  user_data = <<EOF
        #! /bin/bash
        yum update -y
        yum install httpd -y
        FOLDER="https://raw.githubusercontent.com/Ali-ylmz/aws_devops/main/aws/projects/001-kittens-carousel-static-website-ec2/static-web"
        cd /var/www/html
        wget $FOLDER/index.html
        wget $FOLDER/cat0.jpg
        wget $FOLDER/cat1.jpg
        wget $FOLDER/cat2.jpg
        wget $FOLDER/cat3.png
        systemctl start httpd
        systemctl enable httpd
    EOF

  tags = {
    Name = "tf-kittens-carousel"
  }

  provisioner "local-exec" {
    command = "echo http://${self.public_ip} > public_ip.txt"

  }

  connection {
    host        = self.public_ip
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("firstkey.pem")
  }

  /*   provisioner "remote-exec" {
    inline = [
        "sudo yum update -y",
        "sudo yum install httpd -y",
        "FOLDER='https://raw.githubusercontent.com/Ali-ylmz/my-projects/main/aws/projects/Project-101-kittens-carousel-static-website-ec2/static-web'",
        "cd /var/www/html",
        "wget $FOLDER/index.html",
        "wget $FOLDER/cat0.jpg",
        "wget $FOLDER/cat1.jpg",
        "wget $FOLDER/cat2.jpg",
        "wget $FOLDER/cat3.png",
        "systemctl start httpd",
        "systemctl enable httpd"
    ]
  } */

  /*   provisioner "file" {
    content = self.public_ip
    destination = "/home/ec2-user/my_public_ip.txt"
  } */

}

resource "aws_security_group" "tf-sec-gr" {
  name = "tf-kittens-sg"
  tags = {
    Name = "tf-kittens-sg"
  }

  ingress {
    from_port   = 80
    protocol    = "tcp"
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    protocol    = "tcp"
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    protocol    = -1
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "public_ip" {
  value = aws_instance.tf-ec2.public_ip
}