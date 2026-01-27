output "vpc_id" {
    value = aws_vpc.main.id
}

output "private_subnet_ids" {
    value = [for subnet in aws_subnet.private : subnet.id]
}