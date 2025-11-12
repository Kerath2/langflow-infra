output "vpc_id" {
  description = "ID de la VPC creada"
  value       = ibm_is_vpc.vpc.id
}

output "vpc_name" {
  description = "Nombre de la VPC"
  value       = ibm_is_vpc.vpc.name
}

output "subnet_id" {
  description = "ID de la subnet creada"
  value       = ibm_is_subnet.subnet.id
}

output "subnet_name" {
  description = "Nombre de la subnet"
  value       = ibm_is_subnet.subnet.name
}

output "security_group_id" {
  description = "ID del security group"
  value       = ibm_is_security_group.sg.id
}

output "security_group_name" {
  description = "Nombre del security group"
  value       = ibm_is_security_group.sg.name
}

output "public_gateway_id" {
  description = "ID del Public Gateway (si está habilitado)"
  value       = var.enable_public_gateway ? ibm_is_public_gateway.pgw[0].id : null
}
