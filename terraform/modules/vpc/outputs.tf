output "vpc_id" {
  value = aws_vpc.vpn_vpc.id
}

output "subnet_id" {
  value = aws_subnet.vpn_subnet.id
}