resource "aws_security_group" "vpn_sg" {
  name        = "enterprise-vpn-sg"
  description = "Security group for WireGuard VPN infrastructure"

  vpc_id = var.vpc_id

  # WireGuard VPN
  ingress {
    description = "WireGuard VPN - open to all so clients can connect from anywhere"
    from_port   = var.vpn_port
    to_port     = var.vpn_port
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SSH access (admin only)
  ingress {
    description = "SSH Access - restricted to admin IPs only"
    from_port   = var.ssh_port
    to_port     = var.ssh_port
    protocol    = "tcp"
    cidr_blocks = var.ssh_allowed_cidr
  }

  # Grafana
  ingress {
    description = "Grafana Dashboard"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/24"]
  }

  # Prometheus
  ingress {
    description = "Prometheus UI"
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/24"]
  }

  # outbound everything
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