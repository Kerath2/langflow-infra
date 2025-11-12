# Módulo de Networking
module "networking" {
  source = "./modules/networking"

  prefix            = var.prefix
  zone              = var.zone
  resource_group_id = var.resource_group_id

  # Configuración de subnet
  subnet_ip_count = var.subnet_ip_count

  # Configuración de seguridad
  ssh_allowed_cidr = var.ssh_allowed_cidr

  # Configuración de Langflow
  langflow_enabled      = var.langflow_enabled
  langflow_base_port    = var.langflow_base_port
  langflow_port_range   = var.langflow_instances_per_vsi
  langflow_allowed_cidr = var.langflow_allowed_cidr

  # Configuración de Postgres
  postgres_enabled      = var.postgres_enabled
  postgres_base_port    = var.postgres_base_port
  postgres_port_range   = var.langflow_instances_per_vsi
  postgres_allowed_cidr = var.postgres_allowed_cidr

  # Public Gateway
  enable_public_gateway = var.enable_public_gateway

  tags = var.tags
}

# Módulo de Compute
module "compute" {
  source = "./modules/compute"

  prefix            = var.prefix
  zone              = var.zone
  resource_group_id = var.resource_group_id

  # Referencias al módulo de networking
  vpc_id            = module.networking.vpc_id
  subnet_id         = module.networking.subnet_id
  security_group_id = module.networking.security_group_id

  # Configuración de VSIs
  vsi_count   = var.vsi_count
  vsi_profile = var.vsi_profile

  # Sistema operativo
  os_image_name = var.os_image_name

  # SSH
  ssh_public_key = var.ssh_public_key

  # Cloud-init
  cloud_init_template_path = var.cloud_init_template_path

  # Configuración de Langflow
  langflow_instances_per_vsi = var.langflow_instances_per_vsi
  langflow_base_port         = var.langflow_base_port

  # Configuración de Postgres
  postgres_base_port = var.postgres_base_port

  # API Key para Langflow
  api_key = var.api_key

  # Floating IPs
  enable_floating_ips = var.enable_floating_ips

  tags = var.tags

  # Dependencia explícita para asegurar que la red esté lista
  depends_on = [module.networking]
}
