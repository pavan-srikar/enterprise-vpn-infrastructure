module "vpn_vpc" {
  source = "./modules/vpc"
}

module "vpn_security_group" {
  source = "./modules/security-group"

  vpc_id = module.vpn_vpc.vpc_id
}

module "vpn_ec2" {
  source = "./modules/ec2"

  instance_type = var.instance_type
  key_name      = var.key_name

  subnet_id         = module.vpn_vpc.subnet_id
  security_group_id = module.vpn_security_group.security_group_id
}