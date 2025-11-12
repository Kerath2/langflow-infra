# Módulo de Networking

Este módulo gestiona toda la infraestructura de red para IBM Cloud VPC.

## Recursos creados

- VPC (Virtual Private Cloud)
- Subnet
- Security Group con reglas configurables
- Public Gateway (opcional)

## Variables

Ver `variables.tf` para la lista completa de variables configurables.

## Outputs

- `vpc_id` - ID de la VPC
- `subnet_id` - ID de la subnet
- `security_group_id` - ID del security group
