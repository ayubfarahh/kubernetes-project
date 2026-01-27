resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/24"
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

resource "aws_nat_gateway" "example" {
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.public["public_1"].id

  depends_on = [aws_internet_gateway.gw]
}

