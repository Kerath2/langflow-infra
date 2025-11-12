# VPC
resource "ibm_is_vpc" "vpc" {
  name           = "${var.prefix}-vpc"
  resource_group = var.resource_group_id
  tags           = var.tags
}

# Subnet
resource "ibm_is_subnet" "subnet" {
  name                     = "${var.prefix}-subnet"
  vpc                      = ibm_is_vpc.vpc.id
  zone                     = var.zone
  total_ipv4_address_count = var.subnet_ip_count
  resource_group           = var.resource_group_id
  tags                     = var.tags
}

# Security Group
resource "ibm_is_security_group" "sg" {
  name           = "${var.prefix}-sg"
  vpc            = ibm_is_vpc.vpc.id
  resource_group = var.resource_group_id
  tags           = var.tags
}

# Security Group Rule - SSH
resource "ibm_is_security_group_rule" "ssh_inbound" {
  group     = ibm_is_security_group.sg.id
  direction = "inbound"
  remote    = var.ssh_allowed_cidr

  tcp {
    port_min = 22
    port_max = 22
  }
}

# Security Group Rules - Puertos de Langflow (dinámico)
resource "ibm_is_security_group_rule" "langflow_ports" {
  count     = var.langflow_enabled ? 1 : 0
  group     = ibm_is_security_group.sg.id
  direction = "inbound"
  remote    = var.langflow_allowed_cidr

  tcp {
    port_min = var.langflow_base_port
    port_max = var.langflow_base_port + var.langflow_port_range - 1
  }
}

# Security Group Rules - Puertos de Postgres (dinámico)
resource "ibm_is_security_group_rule" "postgres_ports" {
  count     = var.postgres_enabled ? 1 : 0
  group     = ibm_is_security_group.sg.id
  direction = "inbound"
  remote    = var.postgres_allowed_cidr

  tcp {
    port_min = var.postgres_base_port
    port_max = var.postgres_base_port + var.postgres_port_range - 1
  }
}

# Security Group Rule - Outbound (permitir todo el tráfico saliente)
resource "ibm_is_security_group_rule" "outbound_all" {
  group     = ibm_is_security_group.sg.id
  direction = "outbound"
  remote    = "0.0.0.0/0"
}

# Public Gateway (opcional, para acceso a internet desde instancias privadas)
resource "ibm_is_public_gateway" "pgw" {
  count          = var.enable_public_gateway ? 1 : 0
  name           = "${var.prefix}-pgw"
  vpc            = ibm_is_vpc.vpc.id
  zone           = var.zone
  resource_group = var.resource_group_id
  tags           = var.tags
}

# Attach Public Gateway to Subnet
resource "ibm_is_subnet_public_gateway_attachment" "pgw_attachment" {
  count          = var.enable_public_gateway ? 1 : 0
  subnet         = ibm_is_subnet.subnet.id
  public_gateway = ibm_is_public_gateway.pgw[0].id
}
