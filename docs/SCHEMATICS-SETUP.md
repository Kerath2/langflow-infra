# Despliegue con IBM Cloud Schematics

## 📋 ¿Qué es Schematics?

**IBM Cloud Schematics** es el servicio de Terraform administrado de IBM Cloud. Te permite ejecutar Terraform sin instalarlo localmente, con estado administrado y una UI web intuitiva.

## 🚀 Despliegue Paso a Paso

### Opción 1: Via UI de IBM Cloud (Recomendado)

#### Paso 1: Subir Código a GitHub/GitLab

1. Sube este repositorio a GitHub, GitLab o IBM Cloud Git:

```bash
# Si aún no está en Git
git init
git add .
git commit -m "Initial Langflow infrastructure"
git branch -M main
git remote add origin https://github.com/tu-usuario/langflow-infra.git
git push -u origin main
```

**Importante**: No subas `terraform.tfvars` con tu API key real. Usa `.gitignore`:

```bash
echo "terraform.tfvars" >> .gitignore
echo "*.tfstate*" >> .gitignore
echo ".terraform/" >> .gitignore
```

#### Paso 2: Crear Workspace en Schematics

1. Ve a IBM Cloud Console: https://cloud.ibm.com
2. Busca **"Schematics"** en el menú o ve a: https://cloud.ibm.com/schematics/workspaces
3. Haz clic en **"Create workspace"**

#### Paso 3: Configurar Repository

Completa el formulario:

| Campo | Valor |
|-------|-------|
| **Workspace name** | `langflow-production` |
| **Resource group** | Selecciona tu resource group |
| **Location** | Selecciona región (ej: `us-south`) |
| **Description** | "Langflow + PostgreSQL infrastructure" |

**Repository settings**:

| Campo | Valor |
|-------|-------|
| **Repository URL** | `https://github.com/tu-usuario/langflow-infra` |
| **Personal access token** | (opcional, solo si es repo privado) |
| **Terraform version** | Selecciona `terraform_v1.5` o superior |

Haz clic en **"Next"**

#### Paso 4: Configurar Variables

En la sección de variables, agrega las siguientes (marca las sensibles como **Sensitive**):

##### Variables Requeridas

| Variable | Valor | Sensitive | Descripción |
|----------|-------|-----------|-------------|
| `ibmcloud_api_key` | `tu-ibm-api-key` | ✅ Sí | IBM Cloud API Key |
| `api_key` | `sk-proj-tu-api-key` | ✅ Sí | API Key para Langflow (OpenAI/Anthropic/etc) |
| `ssh_public_key` | `ssh-rsa AAAAB3...` | ❌ No | Tu clave SSH pública |

##### Variables Opcionales (con defaults)

| Variable | Valor Default | Descripción |
|----------|---------------|-------------|
| `region` | `us-south` | Región de IBM Cloud |
| `zone` | `us-south-1` | Zona dentro de la región |
| `prefix` | `langflow` | Prefijo para recursos |
| `vsi_count` | `2` | Número de VSIs |
| `vsi_profile` | `cx2-4x8` | Perfil de VSI |
| `langflow_instances_per_vsi` | `2` | Instancias de Langflow por VSI |
| `enable_floating_ips` | `true` | Crear IPs públicas |

Para agregar una variable:
1. Haz clic en **"Add variable"**
2. Ingresa el nombre (ej: `ibmcloud_api_key`)
3. Ingresa el valor
4. Si es sensible, marca **"Sensitive"**
5. Repite para todas las variables

#### Paso 5: Generar Plan

1. Haz clic en **"Generate plan"**
2. Schematics ejecutará `terraform plan`
3. Espera 1-2 minutos
4. Revisa el plan en la sección **"Jobs"**

Verás qué recursos se crearán:
- VPC
- Subnet
- Security Group
- 2 VSIs (o las que configuraste)
- Floating IPs
- SSH Key

#### Paso 6: Apply

1. Si el plan se ve bien, haz clic en **"Apply plan"**
2. Schematics ejecutará `terraform apply`
3. Este proceso toma **5-7 minutos**

Puedes ver el progreso en tiempo real en la sección de logs.

#### Paso 7: Ver Outputs

Una vez completado, ve a la pestaña **"Outputs"**:

Verás:
- **vsi_floating_ips**: IPs públicas de tus VSIs
- **langflow_urls**: URLs de acceso a Langflow
- **ssh_commands**: Comandos SSH para conectarte

Ejemplo:
```
langflow_urls = [
  "http://169.48.123.45:7861",
  "http://169.48.123.45:7862",
  "http://169.48.123.46:7861",
  "http://169.48.123.46:7862"
]
```

#### Paso 8: Verificar Deployment

Espera **3-5 minutos adicionales** después del apply para que cloud-init complete:

1. Instalar Podman
2. Levantar PostgreSQL y Langflow
3. Configurar variable `API_KEY`

**Verificar desde SSH**:

```bash
# SSH a la primera VSI
ssh root@<floating-ip>

# Ver logs de instalación
tail -f /var/log/services-setup.log

# Ver logs de configuración de API key
tail -f /var/log/api-key-setup.log

# Ver contenedores corriendo
podman ps
```

**Verificar desde el navegador**:

Abre cualquiera de los URLs de Langflow que viste en outputs.

---

### Opción 2: Via IBM Cloud CLI

Si prefieres usar la terminal:

#### 1. Instalar IBM Cloud CLI

```bash
# macOS
curl -fsSL https://clis.cloud.ibm.com/install/osx | sh

# Linux
curl -fsSL https://clis.cloud.ibm.com/install/linux | sh

# Windows (PowerShell)
iex(New-Object Net.WebClient).DownloadString('https://clis.cloud.ibm.com/install/powershell')
```

#### 2. Instalar plugin de Schematics

```bash
ibmcloud plugin install schematics
```

#### 3. Login

```bash
ibmcloud login --sso
# O con API key:
ibmcloud login --apikey @~/ibm-api-key.txt
```

#### 4. Crear Workspace

```bash
ibmcloud schematics workspace new \
  --name langflow-production \
  --location us-south \
  --resource-group default \
  --github-token "" \
  --repo-url https://github.com/tu-usuario/langflow-infra \
  --terraform-version terraform_v1.5
```

Guarda el `workspace_id` que te devuelve.

#### 5. Configurar Variables

Crea archivo con variables (sin valores sensibles):

```bash
cat > variables.json <<'EOF'
[
  {
    "name": "ibmcloud_api_key",
    "value": "TU_IBM_API_KEY",
    "type": "string",
    "secure": true
  },
  {
    "name": "api_key",
    "value": "sk-proj-TU_API_KEY",
    "type": "string",
    "secure": true
  },
  {
    "name": "ssh_public_key",
    "value": "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQ...",
    "type": "string"
  },
  {
    "name": "region",
    "value": "us-south",
    "type": "string"
  },
  {
    "name": "vsi_count",
    "value": "2",
    "type": "string"
  }
]
EOF
```

Aplicar variables:

```bash
ibmcloud schematics workspace update \
  --id <workspace_id> \
  --var-file variables.json
```

#### 6. Generate Plan

```bash
ibmcloud schematics plan --id <workspace_id>
```

#### 7. Apply

```bash
ibmcloud schematics apply --id <workspace_id>
```

#### 8. Ver Outputs

```bash
ibmcloud schematics workspace output --id <workspace_id>
```

---

## 🔧 Gestión del Workspace

### Ver Estado de Recursos

```bash
# Via CLI
ibmcloud schematics workspace get --id <workspace_id>

# Via UI
https://cloud.ibm.com/schematics/workspaces/<workspace_id>
```

### Actualizar Infraestructura

Si cambias algo en el código:

1. **Via UI**:
   - Ve al workspace
   - Haz clic en **"Pull latest"** para actualizar desde Git
   - **"Generate plan"**
   - **"Apply plan"**

2. **Via CLI**:
   ```bash
   ibmcloud schematics workspace update --id <workspace_id> --pull-latest
   ibmcloud schematics plan --id <workspace_id>
   ibmcloud schematics apply --id <workspace_id>
   ```

### Destruir Infraestructura

**⚠️ CUIDADO: Esto eliminará todo**

1. **Via UI**:
   - Ve al workspace
   - Actions > **"Destroy resources"**
   - Confirma escribiendo el nombre del workspace

2. **Via CLI**:
   ```bash
   ibmcloud schematics destroy --id <workspace_id>
   ```

---

## 📊 Monitoreo y Logs

### Ver Logs de Apply/Destroy

**Via UI**:
1. Ve al workspace
2. Pestaña **"Jobs"**
3. Haz clic en cualquier job para ver logs detallados

**Via CLI**:
```bash
# Listar jobs
ibmcloud schematics workspace jobs --id <workspace_id>

# Ver logs de un job específico
ibmcloud schematics logs --id <workspace_id> --job-id <job_id>
```

### Descargar tfstate

Si necesitas el archivo de estado:

```bash
ibmcloud schematics state pull --id <workspace_id> > terraform.tfstate
```

---

## 🔐 Seguridad y Mejores Prácticas

### 1. Nunca subas credenciales a Git

```bash
# .gitignore DEBE incluir:
terraform.tfvars
*.tfstate
*.tfstate.backup
.terraform/
*.auto.tfvars
```

### 2. Usa Variables Sensibles

En Schematics, marca como **Sensitive**:
- `ibmcloud_api_key`
- `api_key`
- Cualquier otra credencial

### 3. Restringe Acceso al Workspace

En IBM Cloud IAM:
1. Ve a **"Manage" > "Access (IAM)"**
2. Asigna roles específicos:
   - **Viewer**: Solo lectura
   - **Operator**: Puede ejecutar apply/destroy
   - **Administrator**: Control total

### 4. Usa Resource Groups

Organiza tus workspaces por entorno:
- `langflow-dev`
- `langflow-staging`
- `langflow-production`

---

## 🐛 Troubleshooting

### Error: "Failed to clone repository"

**Solución**: Verifica que la URL del repositorio sea pública o proporciona un Personal Access Token

### Error: "Invalid credentials"

**Solución**: Verifica que `ibmcloud_api_key` sea válida:
```bash
ibmcloud login --apikey <tu-api-key>
```

### Error: "Quota exceeded"

**Solución**: Verifica tus límites en IBM Cloud:
```bash
ibmcloud resource quotas
```

### Los contenedores no arrancan

**Solución**: SSH a la VSI y revisa logs:
```bash
ssh root@<floating-ip>
tail -100 /var/log/cloud-init-output.log
tail -100 /var/log/services-setup.log
```

---

## 📚 Recursos Adicionales

- **IBM Cloud Schematics Docs**: https://cloud.ibm.com/docs/schematics
- **Terraform IBM Provider**: https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs
- **IBM Cloud CLI**: https://cloud.ibm.com/docs/cli

---

## 🎯 Siguiente Paso

Después de que Schematics complete el apply:

1. ✅ Espera 3-5 minutos para que cloud-init termine
2. ✅ Accede a cualquier URL de Langflow de los outputs
3. ✅ Ve a Settings > Global Variables
4. ✅ Verifica que `API_KEY` esté configurada
5. ✅ Importa o crea flows usando `{{API_KEY}}`
6. ✅ ¡Empieza a construir!

---

## 💡 Tips Pro

### 1. Monitoreo Continuo

Crea un cronjob que verifique el estado:

```bash
*/5 * * * * ibmcloud schematics workspace get --id <workspace_id> | grep -q "ACTIVE"
```

### 2. Backup de Estado

Descarga el tfstate regularmente:

```bash
ibmcloud schematics state pull --id <workspace_id> > backup-$(date +%Y%m%d).tfstate
```

### 3. Tags para Costos

Usa tags para tracking de costos:

```hcl
tags = ["team:devops", "project:langflow", "env:prod", "cost-center:engineering"]
```

### 4. Multiple Workspaces

Crea diferentes workspaces para cada entorno:

```bash
# Dev
ibmcloud schematics workspace new --name langflow-dev ...

# Staging
ibmcloud schematics workspace new --name langflow-staging ...

# Production
ibmcloud schematics workspace new --name langflow-production ...
```
