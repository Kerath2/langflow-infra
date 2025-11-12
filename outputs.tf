# Networking Outputs
output "vpc_id" {
  description = "ID de la VPC creada"
  value       = module.networking.vpc_id
}

output "vpc_name" {
  description = "Nombre de la VPC"
  value       = module.networking.vpc_name
}

output "subnet_id" {
  description = "ID de la subnet creada"
  value       = module.networking.subnet_id
}

output "security_group_id" {
  description = "ID del security group"
  value       = module.networking.security_group_id
}

# Compute Outputs
output "vsi_ids" {
  description = "IDs de las VSIs creadas"
  value       = module.compute.vsi_ids
}

output "vsi_names" {
  description = "Nombres de las VSIs creadas"
  value       = module.compute.vsi_names
}

output "vsi_private_ips" {
  description = "IPs privadas de las VSIs"
  value       = module.compute.vsi_private_ips
}

output "vsi_public_ips" {
  description = "IPs públicas de las VSIs (Floating IPs)"
  value       = module.compute.vsi_public_ips
}

output "vsi_details" {
  description = "Detalles completos de las VSIs"
  value       = module.compute.vsi_details
}

# SSH & Access Outputs
output "ssh_connection_commands" {
  description = "Comandos SSH para conectarse a cada VSI"
  value       = module.compute.ssh_connection_commands
}

# Langflow Outputs
output "langflow_urls" {
  description = "URLs de todas las instancias de Langflow"
  value       = module.compute.langflow_urls
}

output "langflow_summary" {
  description = "Resumen de la configuración de Langflow"
  value = {
    total_vsis               = var.vsi_count
    instances_per_vsi        = var.langflow_instances_per_vsi
    total_langflow_instances = var.vsi_count * var.langflow_instances_per_vsi
    base_port                = var.langflow_base_port
    port_range               = "${var.langflow_base_port}-${var.langflow_base_port + var.langflow_instances_per_vsi - 1}"
  }
}

# Formatted Outputs
output "deployment_info" {
  description = "Información completa del despliegue"
  value = <<-EOT
  VPC:                ${module.networking.vpc_name}
  Security Group:     ${module.networking.security_group_name}

  VSIs Created:       ${var.vsi_count}
  Instances per VSI:  ${var.langflow_instances_per_vsi}
  Total Langflow:     ${var.vsi_count * var.langflow_instances_per_vsi}

  Port Range:         ${var.langflow_base_port}-${var.langflow_base_port + var.langflow_instances_per_vsi - 1}

  Access URLs:
  ${join("\n  ", module.compute.langflow_urls[*].url)}

  SSH Commands:
  ${join("\n  ", module.compute.ssh_connection_commands)}

  Note: Wait 3-5 minutes after deployment for Langflow to fully start.

  EOT
}
