resource "aws_security_group" "vpn_sg" {
  name        = "enterprise-vpn-sg"
  description = "Security group for WireGuard VPN infrastructure"

  vpc_id = var.vpc_id

  ingress {
    description = "WireGuard VPN - open to all so clients can connect from anywhere"
    from_port   = var.vpn_port
    to_port     = var.vpn_port
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH Access - restricted to admin IPs only"
    from_port   = var.ssh_port
    to_port     = var.ssh_port
    protocol    = "tcp"
    cidr_blocks = var.ssh_allowed_cidr
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "enterprise-vpn-sg"
  }
}