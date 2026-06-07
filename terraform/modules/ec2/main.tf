resource "aws_instance" "vpn_server" {
ami                    = "ami-0c02fb55956c7d316"
instance_type          = var.instance_type
key_name               = var.key_name
vpc_security_group_ids = [var.security_group_id]

tags = {
Name = "Enterprise-VPN-Gateway"
}
}
