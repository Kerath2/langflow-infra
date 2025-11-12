# Configuración Automática de API_KEY en Langflow

## 📋 Resumen

El proyecto ahora configura automáticamente la variable global `API_KEY` en todas las instancias de Langflow durante el despliegue con Terraform en IBM Cloud.

## 🚀 Cómo Usar

### 1. Configurar tu API Key en Terraform

Edita tu archivo `terraform.tfvars`:

```hcl
# IBM Cloud API Key
ibmcloud_api_key = "tu-ibm-cloud-api-key"

# API Key para Langflow (OpenAI, Anthropic, Google, etc.)
api_key = "sk-proj-tu-api-key-real-aqui"

# ... resto de configuración
```

### 2. Desplegar con Terraform

```bash
terraform init
terraform plan
terraform apply
```

### 3. Esperar a que Complete

El proceso toma aproximadamente **3-5 minutos**:

1. ⏱️ 1-2 min: Terraform crea la infraestructura (VPC, VSIs, etc.)
2. ⏱️ 2-3 min: Cloud-init instala Podman, PostgreSQL y Langflow
3. ⏱️ 1-2 min: Script configura variables `API_KEY` en cada Langflow

### 4. Usar la Variable en tus Flows

Una vez desplegado, en Langflow:

1. Abre cualquier instancia de Langflow (puerto 7861, 7862, etc.)
2. Crea un flow con un componente Language Model
3. En el campo **API Key**, escribe:
   ```
   {{API_KEY}}
   ```
4. La variable se autocompletará con tu clave

## 📊 Qué Hace Automáticamente

### Durante el Despliegue

El `cloud-init.yaml.tpl` ejecuta dos scripts:

#### 1. `/root/start-services.sh`
- Levanta PostgreSQL con credenciales predefinidas
- Levanta Langflow conectado a PostgreSQL
- Habilita auto_login en Langflow

#### 2. `/root/configure-api-keys.sh` (en background)
- Espera 30 segundos a que Langflow esté listo
- Para cada instancia de Langflow:
  - Obtiene token via `/api/v1/auto_login`
  - Crea variable global `API_KEY` via `/api/v1/variables/`
  - Tipo: `Credential` (oculta el valor)
  - Campos aplicables: OpenAI, Anthropic, Google API Keys

### Logs

Puedes verificar el progreso conectándote via SSH a la VSI:

```bash
# Ver logs de instalación de servicios
tail -f /var/log/services-setup.log

# Ver logs de configuración de API keys
tail -f /var/log/api-key-setup.log

# Ver credenciales de PostgreSQL
cat /root/postgres-credentials.txt
```

## 🔍 Verificación

### Verificar que la Variable Existe

SSH a la VSI y ejecuta:

```bash
# Obtener token de auto_login
TOKEN=$(curl -s http://localhost:7861/api/v1/auto_login | grep -o '"access_token":"[^"]*' | cut -d'"' -f4)

# Listar variables globales
curl -s "http://localhost:7861/api/v1/variables/" \
  -H "Authorization: Bearer $TOKEN" | jq '.'
```

Deberías ver:

```json
[
  {
    "id": "xxx-xxx-xxx",
    "name": "API_KEY",
    "type": "Credential",
    "value": null,
    "default_fields": ["OpenAI API Key", "Anthropic API Key", "Google API Key"]
  }
]
```

**Nota**: `value: null` es normal. Por seguridad, las credenciales no se devuelven en el GET, pero el valor está almacenado.

## 🏗️ Arquitectura

### Flujo de Deployment

```
Terraform Apply
    ↓
Crea VSI con cloud-init
    ↓
cloud-init ejecuta:
    1. Instala Podman
    2. Ejecuta start-services.sh
       - Levanta Postgres (localhost:5432)
       - Levanta Langflow (localhost:7861)
         • LANGFLOW_DATABASE_URL="postgresql://..."
         • LANGFLOW_AUTO_LOGIN=true
    3. Ejecuta configure-api-keys.sh (background)
       - Espera 30s
       - Loop por cada instancia:
         • curl auto_login → token
         • curl POST variables/ → crea API_KEY
    ↓
Langflow listo con API_KEY configurada
```

### Conexión PostgreSQL ↔ Langflow

```
Langflow Container (puerto 7861)
    ↓ DATABASE_URL
PostgreSQL Container (puerto 5432)
    ↓ ambos en localhost (misma VM)
```

En Linux/IBM Cloud, `localhost` funciona perfectamente porque ambos contenedores están en la misma VM.

## 🔧 Troubleshooting

### La variable no aparece en Langflow

```bash
# SSH a la VSI
ssh root@<floating-ip>

# Verificar logs
tail -100 /var/log/api-key-setup.log

# Si no se completó, ejecutar manualmente
/root/configure-api-keys.sh
```

### Cambiar la API Key después del despliegue

**Opción 1**: Via UI de Langflow
1. Ve a Settings > Global Variables
2. Edita `API_KEY`
3. Cambia el valor

**Opción 2**: Via API
```bash
# Obtener token
TOKEN=$(curl -s http://localhost:7861/api/v1/auto_login | grep -o '"access_token":"[^"]*' | cut -d'"' -f4)

# Obtener ID de la variable
VAR_ID=$(curl -s "http://localhost:7861/api/v1/variables/" -H "Authorization: Bearer $TOKEN" | grep -o '"id":"[^"]*","name":"API_KEY"' | grep -o '"id":"[^"]*' | cut -d'"' -f4)

# Actualizar valor
curl -X PATCH "http://localhost:7861/api/v1/variables/$VAR_ID" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"value":"nueva-api-key-aqui"}'
```

**Opción 3**: Recrear con Terraform
```bash
# Actualizar terraform.tfvars con nueva api_key
terraform apply
```

### Los contenedores no están corriendo

```bash
# Ver contenedores
podman ps -a

# Ver logs de Langflow
podman logs langflow-1

# Ver logs de PostgreSQL
podman logs postgres-1

# Reiniciar servicios
podman restart postgres-1 langflow-1
```

## 📦 Archivos Modificados

| Archivo | Cambio |
|---------|--------|
| `cloud-init.yaml.tpl` | Agregado script `configure-api-keys.sh` y variable `${api_key}` |
| `modules/compute/main.tf` | Agregado `api_key = var.api_key` en template vars |
| `modules/compute/variables.tf` | Agregada variable `api_key` (sensitive) |
| `main.tf` | Pasado `api_key = var.api_key` al módulo compute |
| `variables.tf` | Agregada variable `api_key` (sensitive) |
| `terraform.tfvars.example` | Agregado ejemplo de `api_key` |

## 🔒 Seguridad

- La variable `api_key` está marcada como `sensitive = true` en Terraform
- Terraform no mostrará el valor en outputs ni logs
- En Langflow, el tipo `Credential` oculta el valor en la UI
- Las API responses no devuelven el valor real de las credenciales
- **Importante**: No commites `terraform.tfvars` con tu API key real a Git

## 🎯 Ventajas

1. **Automatización Total**: No necesitas configurar manualmente en cada instancia
2. **Escalable**: Funciona con N instancias de Langflow por VSI
3. **Portable**: Los flows que usan `{{API_KEY}}` funcionan en todas las instancias
4. **Seguro**: La API key se marca como sensitive en Terraform y Langflow
5. **Flexible**: Funciona con cualquier API key (OpenAI, Anthropic, Google, etc.)

## 📝 Próximos Pasos

Después del deployment:

1. SSH a tu VSI: `ssh root@<floating-ip>`
2. Verifica que los servicios estén corriendo: `podman ps`
3. Accede a Langflow: `http://<floating-ip>:7861`
4. Importa o crea flows usando `{{API_KEY}}`
5. ¡Empieza a construir!
