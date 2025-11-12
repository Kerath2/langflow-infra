variable "prefix" {
  description = "Prefijo para nombrar todos los recursos"
  type        = string
}

variable "zone" {
  description = "IBM Cloud zone"
  type        = string
}

variable "resource_group_id" {
  description = "ID del Resource Group"
  type        = string
  default     = null
}

variable "vpc_id" {
  description = "ID de la VPC donde se crearán las VSIs"
  type        = string
}

variable "subnet_id" {
  description = "ID de la subnet donde se desplegarán las VSIs"
  type        = string
}

variable "security_group_id" {
  description = "ID del security group a aplicar a las VSIs"
  type        = string
}

variable "ssh_public_key" {
  description = "Clave pública SSH para acceder a las VSIs"
  type        = string
}

variable "vsi_count" {
  description = "Número de VSIs a crear"
  type        = number
  default     = 1
  validation {
    condition     = var.vsi_count > 0 && var.vsi_count <= 100
    error_message = "El número de VSIs debe estar entre 1 y 100."
  }
}

variable "vsi_profile" {
  description = "Perfil de la VSI (determina CPU y RAM)"
  type        = string
  default     = "cx2-2x4"
  validation {
    condition     = can(regex("^[a-z0-9]+-[0-9]+x[0-9]+$", var.vsi_profile))
    error_message = "El perfil debe seguir el formato: cx2-2x4, bx2-4x16, etc."
  }
}

variable "os_image_name" {
  description = "Nombre de la imagen del sistema operativo"
  type        = string
  default     = "ibm-ubuntu-22-04-3-minimal-amd64-1"
}

variable "cloud_init_template_path" {
  description = "Ruta al template de cloud-init"
  type        = string
  default     = "cloud-init.yaml.tpl"
}

variable "langflow_instances_per_vsi" {
  description = "Número de instancias de Langflow por VSI"
  type        = number
  default     = 2
  validation {
    condition     = var.langflow_instances_per_vsi > 0 && var.langflow_instances_per_vsi <= 10
    error_message = "El número de instancias debe estar entre 1 y 10."
  }
}

variable "langflow_base_port" {
  description = "Puerto base para Langflow"
  type        = number
  default     = 7861
}

variable "postgres_base_port" {
  description = "Puerto base para Postgres"
  type        = number
  default     = 5432
}

variable "enable_floating_ips" {
  description = "Crear Floating IPs para acceso público a las VSIs"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags para los recursos"
  type        = list(string)
  default     = []
}

variable "api_key" {
  description = "API Key para configurar en Langflow (OpenAI, Anthropic, Google, etc.)"
  type        = string
  sensitive   = true
}
