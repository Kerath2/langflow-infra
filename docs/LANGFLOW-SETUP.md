# Guía de Setup de Langflow con API Key Preconfigured

Esta guía te ayuda a desplegar Langflow con PostgreSQL usando Podman, con API Key ya configurada para replicar fácilmente en múltiples máquinas.

## 📋 Prerequisitos

- Podman instalado (versión 5.0+)
- API Key válida (OpenAI, Anthropic, Google, etc.)

## 🚀 Despliegue Rápido

### Opción 1: Deployment Completo Automatizado

```bash
# Con API key por defecto (de prueba)
./deploy-with-api-key.sh

# Con tu propia API key
./deploy-with-api-key.sh "sk-proj-tu-api-key-real-aqui"
```

Este script:
1. ✓ Levanta PostgreSQL en puerto 5432
2. ✓ Levanta Langflow en puerto 7861 con la variable `API_KEY` configurada
3. ✓ Conecta ambos servicios automáticamente

### Opción 2: Deployment Manual

```bash
# 1. Levantar solo los servicios base
./local-setup.sh

# 2. Configurar la API key manualmente (ver secciones siguientes)
```

## 🔑 Métodos para Usar la API Key

### Método 1: Variable de Entorno en el Contenedor (RECOMENDADO)

Si usaste `deploy-with-api-key.sh`, la variable ya está configurada. En Langflow:

1. Abre http://localhost:7861
2. Crea o importa un flow
3. En el componente Language Model, en el campo "API Key" escribe:
   ```
   {{API_KEY}}
   ```
4. Langflow automáticamente usará la variable de entorno

**Ventaja**: No necesitas exponer la API key en el JSON del flow. Puedes compartir el flow sin preocuparte por la seguridad.

### Método 2: Import Flow Preconfigured

Importa uno de los flows preconfigured:

#### Flow con API Key Hardcoded (para testing rápido)
```bash
# En Langflow UI:
# 1. Clic en "Import" o icono de importar
# 2. Selecciona: preconfigured-openai-flow.json
# 3. La API key ya está seteada
```

#### Flow con Variable de Entorno (para producción)
```bash
# En Langflow UI:
# 1. Clic en "Import"
# 2. Selecciona: preconfigured-openai-flow-with-env.json
# 3. Este flow usa {{API_KEY}} automáticamente
```

### Método 3: Setear Variable Post-Deploy

Si ya tienes Langflow corriendo sin la variable:

```bash
# Opción A: Reiniciar con variable
podman stop langflow-1
podman rm langflow-1
podman run -d \
  --name langflow-1 \
  -p 7861:7860 \
  -e API_KEY="sk-proj-tu-api-key" \
  -v langflow_data_1:/app/langflow \
  docker.io/langflowai/langflow:latest

# Opción B: Usar Global Variables en Langflow UI
# 1. Ve a Settings > Global Variables
# 2. Crea variable: API_KEY = tu-api-key
# 3. Usa {{API_KEY}} en tus flows
```

## 📦 Archivos Importantes

| Archivo | Descripción |
|---------|-------------|
| `deploy-with-api-key.sh` | Script completo de deployment con API key |
| `local-setup.sh` | Script base para levantar servicios sin config |
| `preconfigured-openai-flow.json` | Flow con API key hardcoded (testing) |
| `preconfigured-openai-flow-with-env.json` | Flow con variable de entorno (producción) |
| `setup-langflow-flow.sh` | Script helper con opciones de configuración |

## 🔄 Replicar en Múltiples Máquinas

### Paso 1: Preparar en la Primera Máquina

```bash
# 1. Haz el deployment con tu API key
./deploy-with-api-key.sh "sk-proj-tu-api-key-real"

# 2. En Langflow UI, crea y prueba tus flows usando {{OPENAI_API_KEY}}

# 3. Exporta tus flows desde Langflow UI
#    (Clic derecho en el flow > Export)

# 4. Guarda los flows exportados en un directorio
mkdir -p flows-production
# Mueve los flows exportados a flows-production/
```

### Paso 2: Desplegar en Otras Máquinas

```bash
# En cada nueva máquina:

# 1. Copia estos archivos
scp deploy-with-api-key.sh user@nueva-maquina:~/
scp -r flows-production/ user@nueva-maquina:~/

# 2. SSH a la nueva máquina
ssh user@nueva-maquina

# 3. Instala Podman (si no está instalado)
# macOS: brew install podman
# Linux: sudo apt install podman  (Ubuntu/Debian)
#        sudo dnf install podman  (Fedora/RHEL)

# 4. Ejecuta el deployment con tu API key
./deploy-with-api-key.sh "tu-api-key-real"

# 5. Importa los flows en Langflow UI
#    http://localhost:7861
#    Import > Selecciona flows de flows-production/
```

### Paso 3: Automatización con Script

Para mayor automatización, crea un script de deployment:

```bash
#!/bin/bash
# deploy-all-machines.sh

MACHINES=("server1.example.com" "server2.example.com" "server3.example.com")
API_KEY="sk-proj-tu-api-key-real"

for machine in "${MACHINES[@]}"; do
  echo "Deploying to $machine..."

  # Copiar archivos
  scp deploy-with-api-key.sh $machine:~/
  scp -r flows-production/ $machine:~/

  # Ejecutar deployment remoto
  ssh $machine "cd ~ && ./deploy-with-api-key.sh '$API_KEY'"

  echo "✓ Deployed to $machine"
done

echo "✓ All machines deployed"
```

## 🔧 Comandos Útiles

```bash
# Ver logs
podman logs -f langflow-1
podman logs -f postgres-1

# Ver estado
podman ps

# Detener servicios
podman stop langflow-1 postgres-1

# Reiniciar servicios
podman restart langflow-1 postgres-1

# Eliminar todo (incluye datos)
podman rm -f langflow-1 postgres-1
podman volume rm pgdata_1 langflow_data_1

# Backup de datos
podman exec postgres-1 pg_dump -U langflow langflow_db > backup.sql

# Restore de datos
cat backup.sql | podman exec -i postgres-1 psql -U langflow -d langflow_db
```

## 🔒 Seguridad

### Para Desarrollo/Testing
- Está bien usar API keys hardcoded en flows locales
- Usa `preconfigured-openai-flow.json`

### Para Producción
- **NUNCA** commites API keys a Git
- Usa siempre variables de entorno: `{{OPENAI_API_KEY}}`
- Usa `preconfigured-openai-flow-with-env.json`
- Configura `.gitignore` para excluir archivos con secrets
- Considera usar Secret Managers (HashiCorp Vault, AWS Secrets Manager, etc.)

## 🐛 Troubleshooting

### Langflow no se conecta a PostgreSQL

```bash
# Verificar que host.containers.internal funciona
podman exec langflow-1 ping -c 2 host.containers.internal

# Si falla, usar IP directa de PostgreSQL
POSTGRES_IP=$(podman inspect postgres-1 --format '{{.NetworkSettings.IPAddress}}')
echo $POSTGRES_IP

# Recrear Langflow con IP directa
podman stop langflow-1 && podman rm langflow-1
podman run -d --name langflow-1 -p 7861:7860 \
  -e LANGFLOW_DATABASE_URL="postgresql://langflow:passw0rd@$POSTGRES_IP:5432/langflow_db" \
  -e OPENAI_API_KEY="tu-api-key" \
  -v langflow_data_1:/app/langflow \
  docker.io/langflowai/langflow:latest
```

### Variable de entorno no funciona

```bash
# Verificar que la variable está seteada en el contenedor
podman exec langflow-1 env | grep API_KEY

# Si no aparece, recrear con la variable
podman stop langflow-1 && podman rm langflow-1
# Usar deploy-with-api-key.sh para recrear
```

### Flow no encuentra la API key

- Asegúrate de usar `{{API_KEY}}` (con llaves dobles)
- Verifica que la variable esté en el contenedor (comando arriba)
- Reinicia Langflow después de setear variables

## 📚 Recursos

- [Documentación de Langflow](https://docs.langflow.org/)
- [Langflow GitHub](https://github.com/logspace-ai/langflow)
- [OpenAI API Documentation](https://platform.openai.com/docs/)

## 🆘 Soporte

Si tienes problemas:
1. Revisa los logs: `podman logs langflow-1`
2. Verifica que los servicios estén corriendo: `podman ps`
3. Consulta la sección de Troubleshooting arriba
