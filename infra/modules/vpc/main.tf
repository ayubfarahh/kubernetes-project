resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

}

resource "aws_subnet" "public" {
  for_each = {
    for k, v in local.subnets : k => v 
    if v.type == "public" 
  }
  
  vpc_id     = aws_vpc.main.id
  cidr_block = each.value.cidr
  availability_zone = each.value.az
  map_public_ip_on_launch = true 


}

resource "aws_subnet" "private" {
  for_each = {
    for k, v in local.subnets : k => v
    if v.type == "private"
  }

  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az


}

resource "aws_eip" "eip" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.eip.allocation_id
  subnet_id     = aws_subnet.public["public_1"].id

  depends_on = [aws_internet_gateway.gw]
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
}

resource "aws_route_table_association" "public_assoc" {
  for_each = {
    for k, v in local.subnets : k => v 
    if v.type == "public" 
  }

  subnet_id      = aws_subnet.public[each.key].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private_assoc" {
  for_each = {
    for k, v in local.subnets : k => v
    if v.type == "private"
  }

  subnet_id      = aws_subnet.private[each.key].id
  route_table_id = aws_route_table.private.id
}