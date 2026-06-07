output "vpn_instance_public_ip" {
description = "Public IP of VPN gateway"
value       = module.vpn_ec2.public_ip
}
