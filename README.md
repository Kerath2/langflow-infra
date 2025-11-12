# Langflow Infrastructure on IBM Cloud

Infraestructura como código (IaC) con Terraform para desplegar múltiples instancias de Langflow + PostgreSQL en IBM Cloud VPC.

## 🎯 ¿Qué Hace Este Proyecto?

Despliega automáticamente:
- ✅ VPC con subnet y security groups
- ✅ N máquinas virtuales (VSIs) en IBM Cloud
- ✅ PostgreSQL (contenedores Podman)
- ✅ Langflow (contenedores Podman)
- ✅ Variable global `API_KEY` pre-configurada en Langflow
- ✅ IPs públicas para acceso

## 🚀 Deploy Rápido con IBM Cloud Schematics

### Paso 1: Sube el Código a GitHub

```bash
git init
git add .
git commit -m "Langflow infrastructure"
git branch -M main
git remote add origin https://github.com/tu-usuario/langflow-infra.git
git push -u origin main
```

### Paso 2: Crea Workspace en Schematics

1. Ve a: https://cloud.ibm.com/schematics/workspaces
2. Haz clic en **"Create workspace"**
3. Completa:
   - **Workspace name**: `langflow-production`
   - **Repository URL**: `https://github.com/tu-usuario/langflow-infra`
   - **Terraform version**: `terraform_v1.5`

### Paso 3: Configura Variables

| Variable | Valor | Sensitive |
|----------|-------|-----------|
| `ibmcloud_api_key` | Tu IBM Cloud API Key | ✅ Sí |
| `api_key` | Tu OpenAI/Anthropic/Google API Key | ✅ Sí |
| `ssh_public_key` | Tu clave SSH pública | ❌ No |

Variables opcionales (tienen defaults):
- `region` = "us-south"
- `vsi_count` = 2
- `vsi_profile` = "cx2-4x8"
- `langflow_instances_per_vsi` = 2

### Paso 4: Deploy

1. Haz clic en **"Generate plan"**
2. Revisa el plan
3. Haz clic en **"Apply plan"**
4. Espera 5-7 minutos

### Paso 5: Accede a Langflow

Ve a la pestaña **"Outputs"** en Schematics para ver las URLs de Langflow.

**Ejemplo**:
```
http://169.48.123.45:7861
http://169.48.123.45:7862
http://169.48.123.46:7861
http://169.48.123.46:7862
```

⏱️ **Espera 3-5 minutos adicionales** después del apply para que cloud-init complete la instalación.

## 📖 Documentación Completa

- **[docs/SCHEMATICS-SETUP.md](docs/SCHEMATICS-SETUP.md)** - Guía detallada para usar IBM Cloud Schematics
- **[docs/API-KEY-SETUP.md](docs/API-KEY-SETUP.md)** - Cómo funciona la configuración automática de API_KEY
- **[docs/LANGFLOW-SETUP.md](docs/LANGFLOW-SETUP.md)** - Información general sobre Langflow

## 🏗️ Arquitectura

```
IBM Cloud VPC
├── Subnet (256 IPs)
├── Security Group (SSH, Langflow, PostgreSQL)
└── VSIs (Ubuntu 22.04)
    └── Podman Containers
        ├── PostgreSQL (localhost:5432, 5433, ...)
        └── Langflow (puerto 7861, 7862, ...)
            └── Variable Global: API_KEY ✅
```

Cada VSI ejecuta:
- N instancias de PostgreSQL (configurable)
- N instancias de Langflow (configurable)
- Cada Langflow conectado a su propio PostgreSQL
- Variable `API_KEY` configurada automáticamente

## 🔧 Configuración Avanzada

Edita `terraform.tfvars` (o variables en Schematics):

```hcl
# Región y zona
region = "us-south"
zone   = "us-south-1"

# Número de VSIs
vsi_count = 3

# Perfil de VSI (CPU y RAM)
vsi_profile = "cx2-4x8"  # 4 vCPU, 8GB RAM

# Instancias de Langflow por VSI
langflow_instances_per_vsi = 3

# Total: 3 VSIs × 3 instancias = 9 instancias de Langflow

# Puertos base
langflow_base_port = 7861  # 7861, 7862, 7863...
postgres_base_port = 5432  # 5432, 5433, 5434...

# Seguridad
ssh_allowed_cidr      = "0.0.0.0/0"  # ⚠️ Restringe en producción
langflow_allowed_cidr = "0.0.0.0/0"
postgres_allowed_cidr = "0.0.0.0/0"
```

## 📦 Estructura del Proyecto

```
langflow-infra/
├── main.tf                    # Configuración principal
├── variables.tf               # Variables de entrada
├── outputs.tf                 # Outputs (IPs, URLs)
├── versions.tf                # Versiones de Terraform
├── provider.tf                # Provider de IBM Cloud
├── cloud-init.yaml.tpl        # Script de inicialización
├── terraform.tfvars.example   # Ejemplo de configuración
│
├── modules/
│   ├── networking/            # VPC, subnet, security groups
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── versions.tf
│   │
│   └── compute/               # VSIs, SSH keys, floating IPs
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── versions.tf
│
└── docs/
    ├── SCHEMATICS-SETUP.md
    ├── API-KEY-SETUP.md
    └── LANGFLOW-SETUP.md
```

## 🔐 Seguridad

### Variables Sensibles

Marca como **Sensitive** en Schematics:
- `ibmcloud_api_key`
- `api_key`

### .gitignore

**NUNCA** subas a Git:
```
terraform.tfvars
*.tfstate
*.tfstate.backup
.terraform/
```

### Restringir Acceso

En producción, restringe los CIDRs:

```hcl
ssh_allowed_cidr      = "203.0.113.0/24"  # Tu IP o VPN
langflow_allowed_cidr = "203.0.113.0/24"
postgres_allowed_cidr = "10.0.0.0/8"      # Solo internal
```

## 🎨 Usar API_KEY en Flows

La variable `API_KEY` se configura automáticamente en todas las instancias de Langflow.

En cualquier componente Language Model:

1. Campo **API Key**: Escribe `{{API_KEY}}`
2. Langflow autocompletará con tu clave
3. Funciona con OpenAI, Anthropic, Google, etc.

## 🔄 Actualizar Infraestructura

### Via Schematics UI

1. Actualiza el código en GitHub
2. En Schematics: **"Pull latest"**
3. **"Generate plan"**
4. **"Apply plan"**

### Via Terraform Local

```bash
terraform plan
terraform apply
```

## 🗑️ Destruir Infraestructura

### Via Schematics

1. Ve al workspace
2. Actions > **"Destroy resources"**
3. Confirma

### Via Terraform Local

```bash
terraform destroy
```

## 📊 Costos Estimados

Ejemplo con configuración default (2 VSIs × cx2-4x8):

| Recurso | Cantidad | Costo/mes (USD) |
|---------|----------|-----------------|
| VSI cx2-4x8 | 2 | ~$120 |
| Floating IPs | 2 | ~$10 |
| VPC | 1 | Gratis |
| **Total** | | **~$130/mes** |

Usa la [calculadora de IBM Cloud](https://cloud.ibm.com/estimator) para estimaciones precisas.

## 🐛 Troubleshooting

### Los contenedores no arrancan

SSH a la VSI:
```bash
ssh root@<floating-ip>

# Ver logs
tail -f /var/log/services-setup.log
tail -f /var/log/api-key-setup.log

# Ver contenedores
podman ps -a

# Reiniciar
podman restart postgres-1 langflow-1
```

### Variable API_KEY no aparece

```bash
# Ejecutar manualmente
ssh root@<floating-ip>
/root/configure-api-keys.sh
```

### Verificar logs en Schematics

1. Ve al workspace
2. Pestaña **"Jobs"**
3. Haz clic en el job más reciente
4. Revisa logs detallados

## 🤝 Contribuir

1. Fork el proyecto
2. Crea una rama (`git checkout -b feature/nueva-funcionalidad`)
3. Commit cambios (`git commit -m 'Add: nueva funcionalidad'`)
4. Push a la rama (`git push origin feature/nueva-funcionalidad`)
5. Abre un Pull Request

## 📄 Licencia

Este proyecto está bajo la Licencia MIT.

## 🆘 Soporte

- **Issues**: https://github.com/tu-usuario/langflow-infra/issues
- **IBM Cloud Docs**: https://cloud.ibm.com/docs
- **Langflow Docs**: https://docs.langflow.org

## ⭐ Características

- ✅ Infraestructura como código con Terraform
- ✅ Compatible con IBM Cloud Schematics
- ✅ Despliegue multi-instancia escalable
- ✅ Configuración automática de API keys
- ✅ PostgreSQL dedicado por instancia
- ✅ Seguridad con Security Groups
- ✅ Estado administrado
- ✅ Documentación completa

---

**Hecho con ❤️ para despliegues rápidos de Langflow en IBM Cloud**
