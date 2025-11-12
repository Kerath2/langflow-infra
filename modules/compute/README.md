# Módulo de Compute

Este módulo gestiona todos los recursos de cómputo para IBM Cloud VPC.

## Recursos creados

- SSH Key
- Virtual Server Instances (VSIs)
- Floating IPs (opcional)
- Cloud-init configuration para Podman y Langflow

## Variables

Ver `variables.tf` para la lista completa de variables configurables.

## Outputs

- `vsi_ids` - IDs de las VSIs
- `vsi_names` - Nombres de las VSIs
- `vsi_public_ips` - IPs públicas (Floating IPs)
- `langflow_urls` - URLs de todas las instancias de Langflow
- `ssh_connection_commands` - Comandos para conectarse por SSH
