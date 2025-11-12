# Troubleshooting: Contenedores No Iniciaron

## Verificar Estado de Cloud-Init

```bash
# Ver si cloud-init terminó de ejecutarse
cloud-init status

# Ver logs de cloud-init
cat /var/log/cloud-init-output.log

# Ver logs específicos de los scripts
cat /var/log/services-setup.log
cat /var/log/api-key-setup.log
```

## Ejecutar Scripts Manualmente

Si cloud-init aún está corriendo o falló, ejecuta los scripts manualmente:

```bash
# 1. Iniciar los servicios (Postgres y Langflow)
/root/start-services.sh

# 2. Esperar 30 segundos y configurar API_KEY
sleep 30
/root/configure-api-keys.sh

# 3. Verificar que los contenedores están corriendo
podman ps

# Deberías ver 4 contenedores:
# - postgres-1, postgres-2
# - langflow-1, langflow-2
```

## Verificar Logs de Contenedores

```bash
# Ver logs de Postgres
podman logs postgres-1
podman logs postgres-2

# Ver logs de Langflow
podman logs langflow-1
podman logs langflow-2

# Ver si hay errores
podman ps -a  # Muestra todos los contenedores (incluso los que fallaron)
```

## Problemas Comunes

### 1. Falta Descargar Imágenes
Si las imágenes no se descargaron:
```bash
podman pull docker.io/library/postgres:16
podman pull docker.io/langflowai/langflow:latest
```

### 2. Permisos de Scripts
```bash
chmod +x /root/start-services.sh
chmod +x /root/configure-api-keys.sh
```

### 3. Reiniciar Contenedores
Si los contenedores existen pero están parados:
```bash
podman start postgres-1 postgres-2
podman start langflow-1 langflow-2
```

### 4. Eliminar y Recrear
Si algo salió mal:
```bash
# Eliminar todos los contenedores
podman rm -f $(podman ps -aq)

# Eliminar volúmenes
podman volume prune -f

# Ejecutar de nuevo
/root/start-services.sh
```
