data "aws_vpc" "selected" {
  filter {
    name   = "tag:Name"
    values = ["stage"]
  }
}

data "aws_subnet" "selected" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }
}

data "aws_security_group" "selected" {
  filter {
    name   = "group-name"
    values = ["sec-grp"]
  }
}

resource "aws_instance" "ftp-server" {
  ami           = "${var.AWS_AMI}"
  instance_type = "${var.AWS_INSTANCE_TYPE}"
  key_name      = "${var.AWS_SSH_KEY}"
  vpc_security_group_ids = [data.aws_security_group.selected.id]
  subnet_id              = data.aws_subnet.selected.id
  associate_public_ip_address = true
	lifecycle {
    	create_before_destroy = true
	}

  tags = {
    Name = "ftp-server"
  }

    connection {

        type    = "ssh"
        user    = "ubuntu"
        private_key = file("${var.PROVISION_SSH_KEY}")
        host    = self.public_ip
    }
  provisioner "file" {
    source      = "provisioner.sh"
    destination = "/home/ubuntu/provisioner.sh"
  }

  # executes the following commands remotely
  provisioner "remote-exec" {
    inline = [
      "$(sudo sh -c 'echo root:${var.ROOT_PASSWORD} | chpasswd')",
      "git clone https://github.com/Premmgr/rtbackup_linux.git",
      "sudo chmod +x /home/ubuntu/provisioner.sh",
      "sh /home/ubuntu/provisioner.sh",
    ]
  }
}
