# IBM Cloud Configuration
variable "ibmcloud_api_key" {
  description = "IBM Cloud API Key"
  type        = string
  sensitive   = true
}

variable "region" {
  description = "IBM Cloud region"
  type        = string
  default     = "us-south"
}

variable "zone" {
  description = "IBM Cloud zone dentro de la región"
  type        = string
  default     = "us-south-1"
}

variable "resource_group_id" {
  description = "ID del Resource Group (opcional)"
  type        = string
  default     = null
}

# General Configuration
variable "prefix" {
  description = "Prefijo para nombrar todos los recursos"
  type        = string
  default     = "langflow"
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*$", var.prefix))
    error_message = "El prefijo debe comenzar con letra minúscula y solo contener letras, números y guiones."
  }
}

variable "tags" {
  description = "Tags para los recursos"
  type        = list(string)
  default     = ["terraform", "langflow"]
}

# Networking Configuration
variable "subnet_ip_count" {
  description = "Número de direcciones IP en la subnet"
  type        = number
  default     = 256
}

variable "ssh_allowed_cidr" {
  description = "CIDR permitido para SSH (0.0.0.0/0 para permitir desde cualquier IP)"
  type        = string
  default     = "0.0.0.0/0"
}

variable "langflow_allowed_cidr" {
  description = "CIDR permitido para acceso a Langflow"
  type        = string
  default     = "0.0.0.0/0"
}

variable "enable_public_gateway" {
  description = "Crear Public Gateway para acceso a internet"
  type        = bool
  default     = false
}

# Compute Configuration
variable "vsi_count" {
  description = "Número de VSIs a crear. Cada VSI = 1 Langflow + 1 PostgreSQL. Para escalar: aumenta este número."
  type        = number
  default     = 2
  validation {
    condition     = var.vsi_count > 0 && var.vsi_count <= 100
    error_message = "El número de VSIs debe estar entre 1 y 100."
  }
}

variable "vsi_profile" {
  description = "Perfil de la VSI (determina CPU y RAM). cx2-2x8 = 2 vCPU, 8GB RAM"
  type        = string
  default     = "cx2-2x8"
}

variable "os_image_name" {
  description = "Nombre de la imagen del sistema operativo"
  type        = string
  default     = "ibm-ubuntu-22-04-3-minimal-amd64-1"
}

variable "ssh_public_key" {
  description = "SSH public key para acceder a las VSIs"
  type        = string
}

variable "cloud_init_template_path" {
  description = "Ruta al template de cloud-init"
  type        = string
  default     = "cloud-init.yaml.tpl"
}

variable "enable_floating_ips" {
  description = "Crear Floating IPs para acceso público"
  type        = bool
  default     = true
}

# Langflow Configuration
variable "langflow_enabled" {
  description = "Habilitar configuración de Langflow"
  type        = bool
  default     = true
}

variable "langflow_instances_per_vsi" {
  description = "Número de instancias de Langflow a ejecutar por VSI (cada una con su PostgreSQL dedicado)"
  type        = number
  default     = 2
  validation {
    condition     = var.langflow_instances_per_vsi > 0 && var.langflow_instances_per_vsi <= 10
    error_message = "El número de instancias de Langflow debe estar entre 1 y 10."
  }
}

variable "langflow_base_port" {
  description = "Puerto base para las instancias de Langflow (se incrementará: 7861, 7862, 7863...)"
  type        = number
  default     = 7861
  validation {
    condition     = var.langflow_base_port >= 1024 && var.langflow_base_port <= 65525
    error_message = "El puerto base debe estar entre 1024 y 65525."
  }
}

# Postgres Configuration
variable "postgres_enabled" {
  description = "Habilitar configuración de Postgres"
  type        = bool
  default     = true
}

variable "postgres_base_port" {
  description = "Puerto base para las instancias de Postgres (se incrementará: 5432, 5433, 5434...)"
  type        = number
  default     = 5432
  validation {
    condition     = var.postgres_base_port >= 1024 && var.postgres_base_port <= 65525
    error_message = "El puerto base debe estar entre 1024 y 65525."
  }
}

variable "postgres_allowed_cidr" {
  description = "CIDR permitido para acceso a Postgres"
  type        = string
  default     = "0.0.0.0/0"
}

# API Key Configuration
variable "api_key" {
  description = "API Key para configurar en Langflow (OpenAI, Anthropic, Google, etc.)"
  type        = string
  sensitive   = true
}
