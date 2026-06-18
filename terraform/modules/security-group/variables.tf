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

variable "ssh_allowed_cidr" {
  description = "List of CIDRs allowed to SSH. Use x.x.x.x/32 for single IPs. Never use 0.0.0.0/0."
  type        = list(string)

  validation {
    condition     = !contains(var.ssh_allowed_cidr, "0.0.0.0/0")
    error_message = "SSH must not be open to the world (0.0.0.0/0)."
  }
}