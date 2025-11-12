output "vsi_ids" {
  description = "IDs de las VSIs creadas"
  value       = ibm_is_instance.vsi[*].id
}

output "vsi_names" {
  description = "Nombres de las VSIs creadas"
  value       = ibm_is_instance.vsi[*].name
}

output "vsi_private_ips" {
  description = "IPs privadas de las VSIs"
  value       = ibm_is_instance.vsi[*].primary_network_interface[0].primary_ip[0].address
}

output "vsi_public_ips" {
  description = "IPs públicas de las VSIs (Floating IPs)"
  value       = var.enable_floating_ips ? ibm_is_floating_ip.fip[*].address : []
}

output "ssh_key_id" {
  description = "ID de la SSH key creada"
  value       = ibm_is_ssh_key.ssh_key.id
}

output "vsi_details" {
  description = "Detalles completos de las VSIs"
  value = [
    for idx, vsi in ibm_is_instance.vsi : {
      name       = vsi.name
      id         = vsi.id
      zone       = vsi.zone
      profile    = vsi.profile
      private_ip = vsi.primary_network_interface[0].primary_ip[0].address
      public_ip  = var.enable_floating_ips ? ibm_is_floating_ip.fip[idx].address : null
    }
  ]
}

output "langflow_urls" {
  description = "URLs de todas las instancias de Langflow"
  value = var.enable_floating_ips ? flatten([
    for i, fip in ibm_is_floating_ip.fip : [
      for j in range(var.langflow_instances_per_vsi) : {
        vsi_name     = ibm_is_instance.vsi[i].name
        instance_num = j + 1
        url          = "http://${fip.address}:${var.langflow_base_port + j}"
        port         = var.langflow_base_port + j
      }
    ]
  ]) : []
}

output "ssh_connection_commands" {
  description = "Comandos SSH para conectarse a cada VSI"
  value = var.enable_floating_ips ? [
    for i, fip in ibm_is_floating_ip.fip : "ssh root@${fip.address}"
  ] : []
}
