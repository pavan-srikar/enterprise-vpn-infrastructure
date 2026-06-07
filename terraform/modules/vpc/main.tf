resource "aws_vpc" "vpn_vpc" {
  cidr_block = "10.10.0.0/16"

  tags = {
    Name = "enterprise-vpn-vpc"
  }
}

resource "aws_subnet" "vpn_subnet" {
  vpc_id                  = aws_vpc.vpn_vpc.id
  cidr_block              = "10.10.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "enterprise-vpn-subnet"
  }
}

resource "aws_internet_gateway" "vpn_igw" {
  vpc_id = aws_vpc.vpn_vpc.id

  tags = {
    Name = "enterprise-vpn-igw"
  }
}

resource "aws_route_table" "vpn_route_table" {
  vpc_id = aws_vpc.vpn_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.vpn_igw.id
  }

  tags = {
    Name = "enterprise-vpn-route-table"
  }
}

resource "aws_route_table_association" "vpn_rta" {
  subnet_id      = aws_subnet.vpn_subnet.id
  route_table_id = aws_route_table.vpn_route_table.id
}