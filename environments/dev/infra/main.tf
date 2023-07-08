data "aws_ami" "Ubuntu_ami" {

  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

}

resource "aws_instance" "project-iac" {

  depends_on = [aws_security_group.sg, aws_subnet.public_subnet]


  ami                         = data.aws_ami.Ubuntu_ami.id
  instance_type               = var.aws.instance_type
  subnet_id                   = aws_subnet.public_subnet.id
  associate_public_ip_address = var.aws.publicip
  key_name                    = var.aws.keyname


  vpc_security_group_ids = [
    aws_security_group.sg.id
  ]

  root_block_device {
    delete_on_termination = true
    volume_size           = 14
    volume_type           = "gp2"
  }
  tags = {
    Environment = "DEV"
    OS          = "UBUNTU"
  }

  user_data = local.script

}

