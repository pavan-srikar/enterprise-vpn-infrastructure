variable "vpn_port" {
  description = "WireGuard VPN UDP port"
  type        = number
  default     = 51820
}

variable "ssh_port" {
  description = "SSH access port"
  type        = number
  default     = 22
}