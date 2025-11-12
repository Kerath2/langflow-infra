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

variable "subnet_ip_count" {
  description = "Número de direcciones IP en la subnet"
  type        = number
  default     = 256
  validation {
    condition     = contains([8, 16, 32, 64, 128, 256, 512, 1024, 2048, 4096, 8192, 16384], var.subnet_ip_count)
    error_message = "El número de IPs debe ser una potencia de 2 entre 8 y 16384."
  }
}

variable "ssh_allowed_cidr" {
  description = "CIDR permitido para conexiones SSH (0.0.0.0/0 para permitir desde cualquier IP)"
  type        = string
  default     = "0.0.0.0/0"
}

variable "langflow_enabled" {
  description = "Habilitar reglas de firewall para Langflow"
  type        = bool
  default     = true
}

variable "langflow_base_port" {
  description = "Puerto base para Langflow"
  type        = number
  default     = 7861
}

variable "langflow_port_range" {
  description = "Número de puertos consecutivos a abrir para Langflow"
  type        = number
  default     = 10
}

variable "langflow_allowed_cidr" {
  description = "CIDR permitido para acceso a Langflow"
  type        = string
  default     = "0.0.0.0/0"
}

variable "postgres_enabled" {
  description = "Habilitar reglas de firewall para Postgres"
  type        = bool
  default     = true
}

variable "postgres_base_port" {
  description = "Puerto base para Postgres"
  type        = number
  default     = 5432
}

variable "postgres_port_range" {
  description = "Número de puertos consecutivos a abrir para Postgres"
  type        = number
  default     = 10
}

variable "postgres_allowed_cidr" {
  description = "CIDR permitido para acceso a Postgres"
  type        = string
  default     = "0.0.0.0/0"
}

variable "enable_public_gateway" {
  description = "Crear Public Gateway para acceso a internet desde instancias privadas"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags para los recursos"
  type        = list(string)
  default     = []
}
