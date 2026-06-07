module "vpn_vpc" {
  source = "./modules/vpc"
}

module "vpn_security_group" {
  source = "./modules/security-group"
}

module "vpn_ec2" {
  source            = "./modules/ec2"
  instance_type     = var.instance_type
  key_name          = var.key_name
  security_group_id = module.vpn_security_group.security_group_id
}