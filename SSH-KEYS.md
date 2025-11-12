# Claves SSH del Proyecto

## 🔑 Claves Generadas

El proyecto incluye un par de claves SSH pre-generadas para facilitar las pruebas:

```
ssh-key-langflow       # Clave privada (🚨 NO SE SUBE A GIT)
ssh-key-langflow.pub   # Clave pública (🚨 NO SE SUBE A GIT)
```

**⚠️ IMPORTANTE**: Estas claves están en `.gitignore` y **NO se subirán a Git** por seguridad.

## 📋 Cómo Usar

### Opción 1: Usar las Claves del Proyecto (Para Pruebas)

1. **Ya están creadas** en el directorio del proyecto
2. **Copia la clave pública**:
   ```bash
   cat ssh-key-langflow.pub
   ```

3. **Pégala en Schematics** cuando configures la variable `ssh_public_key`

4. **Para conectarte via SSH** después del deployment:
   ```bash
   # Obtén la IP pública de los outputs de Schematics
   ssh -i ssh-key-langflow root@<floating-ip>
   ```

### Opción 2: Usar tu Propia Clave SSH (Recomendado para Producción)

1. **Si ya tienes una clave SSH**:
   ```bash
   cat ~/.ssh/id_rsa.pub
   # o
   cat ~/.ssh/id_ed25519.pub
   ```

2. **Copia esa clave pública** y úsala en Schematics

3. **Conéctate normalmente**:
   ```bash
   ssh root@<floating-ip>
   ```

### Opción 3: Crear Nueva Clave Personal

```bash
# Crear nueva clave
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_langflow -C "tu-email@example.com"

# Ver la clave pública
cat ~/.ssh/id_ed25519_langflow.pub

# Conectarte después
ssh -i ~/.ssh/id_ed25519_langflow root@<floating-ip>
```

## 🔐 Configuración en Schematics

Cuando crees el workspace en IBM Cloud Schematics:

1. Ve a la sección **Variables**
2. Agrega variable: `ssh_public_key`
3. Valor: Pega el contenido de `ssh-key-langflow.pub` (o tu clave)
4. **NO marques como "Sensitive"** (las claves públicas no son secretas)

**Ejemplo**:
```
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF20HXoSgavs1MJcKhrGEr0uKspfvuMJdZH1b5BYZDPu langflow-infra-key
```

## 🔗 Conectarse a las VSIs

Una vez desplegado:

### Ver IPs Públicas

En Schematics, ve a la pestaña **Outputs** y verás algo como:
```json
{
  "vsi_floating_ips": ["169.48.123.45", "169.48.123.46"],
  "ssh_commands": [
    "ssh root@169.48.123.45",
    "ssh root@169.48.123.46"
  ]
}
```

### Conectarse

```bash
# Si usas la clave del proyecto
ssh -i ssh-key-langflow root@169.48.123.45

# Si usas tu propia clave (ya en ~/.ssh/)
ssh root@169.48.123.45
```

### Agregar a SSH Config (Opcional)

Para no tener que especificar `-i` cada vez:

```bash
# Edita ~/.ssh/config
nano ~/.ssh/config
```

Agrega:
```
Host langflow-vsi-1
  HostName 169.48.123.45
  User root
  IdentityFile /ruta/completa/a/langflow-infra/ssh-key-langflow

Host langflow-vsi-2
  HostName 169.48.123.46
  User root
  IdentityFile /ruta/completa/a/langflow-infra/ssh-key-langflow
```

Luego conecta simplemente:
```bash
ssh langflow-vsi-1
```

## 🔒 Seguridad

### ✅ Buenas Prácticas

1. **Nunca subas claves privadas a Git** (ya está en `.gitignore`)
2. **No compartas claves privadas** por email, Slack, etc.
3. **Usa contraseñas en claves para producción**:
   ```bash
   ssh-keygen -t ed25519 -f ~/.ssh/id_prod -C "prod-key"
   # Te pedirá una contraseña
   ```

4. **Restringe permisos**:
   ```bash
   chmod 600 ssh-key-langflow
   chmod 644 ssh-key-langflow.pub
   ```

### ⚠️ Para Producción

- **NO uses las claves del proyecto** en producción
- Cada persona del equipo debe usar su propia clave SSH
- Considera usar **IBM Cloud Certificate Manager** para gestión de claves
- Rota las claves periódicamente

## 🗑️ Eliminar Claves

Si quieres regenerar las claves:

```bash
# Eliminar las existentes
rm ssh-key-langflow ssh-key-langflow.pub

# Generar nuevas
ssh-keygen -t ed25519 -f ./ssh-key-langflow -N "" -C "langflow-infra-key"

# Actualizar terraform.tfvars con la nueva clave pública
cat ssh-key-langflow.pub
```

## 📚 Más Información

- [IBM Cloud SSH Keys](https://cloud.ibm.com/docs/vpc?topic=vpc-ssh-keys)
- [GitHub SSH Guide](https://docs.github.com/en/authentication/connecting-to-github-with-ssh)
- [SSH Best Practices](https://www.ssh.com/academy/ssh/key-management)

---

**Recuerda**: Las claves están en `.gitignore` por seguridad. Cada persona que clone el repo necesitará generar sus propias claves o usar las suyas existentes.
