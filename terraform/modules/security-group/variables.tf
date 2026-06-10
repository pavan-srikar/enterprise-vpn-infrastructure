variable "vpn_port" {
  description = "WireGuard VPN port"
  type        = number
  default     = 51820
}

variable "ssh_port" {
  description = "SSH port"
  type        = number
  default     = 22
}

variable "vpc_id" {
  description = "VPC ID where the security group will be created"
  type        = string
}