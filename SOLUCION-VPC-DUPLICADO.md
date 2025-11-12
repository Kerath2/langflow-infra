# Solución: Error VPC Duplicado "langflow-vpc"

## El Problema
```
Error: CreateVPCWithContext failed: Provided Name (langflow-vpc) is not unique
```

El VPC "langflow-vpc" ya existe en IBM Cloud desde un deployment anterior fallido, pero no se destruyó completamente.

---

## ✅ SOLUCIÓN 1: Cambiar el Prefix (MÁS RÁPIDO)

### Paso a Paso en IBM Cloud Schematics:

1. **Ve a tu Workspace en Schematics**
   - URL: https://cloud.ibm.com/schematics/workspaces

2. **Click en "Settings"** (en el menú lateral)

3. **En la sección "Variables"**, encuentra la variable `prefix`
   - Valor actual: `langflow`
   - **Cámbialo a**: `langflow-v2` o `langflow2`

4. **Guarda los cambios** (botón "Save changes")

5. **Ve a "Actions"** → **"Generate plan"**

6. **Espera a que termine** y luego **"Apply plan"**

Esto creará recursos con nombres únicos:
- VPC: `langflow-v2-vpc` (en lugar de `langflow-vpc`)
- VSIs: `langflow-v2-vsi-1`, `langflow-v2-vsi-2`
- Security Group: `langflow-v2-sg`

---

## 🔍 SOLUCIÓN 2: Buscar y Eliminar el VPC Existente

Si prefieres mantener el nombre "langflow", necesitas eliminar el VPC fantasma.

### Usando IBM Cloud CLI:

```bash
# Instalar IBM Cloud CLI (si no lo tienes)
# https://cloud.ibm.com/docs/cli?topic=cli-install-ibmcloud-cli

# Login
ibmcloud login --sso

# Seleccionar tu cuenta
ibmcloud target

# Buscar TODOS los VPCs (en todos los resource groups)
ibmcloud is vpcs --output json | grep -A 5 "langflow-vpc"

# Si lo encuentras, anota su ID y elimínalo
ibmcloud is vpc-delete <VPC_ID>

# Si tiene recursos dependientes (subnets, security groups), elimínalos primero:
ibmcloud is subnets --output json | grep -B 5 "langflow"
ibmcloud is security-groups --output json | grep -B 5 "langflow"
```

**⚠️ Nota**: Puede ser complicado si hay muchos recursos dependientes.

---

## 🎯 RECOMENDACIÓN

**Usa la Solución 1** (cambiar el prefix a `langflow-v2`). Es más rápido y evita conflictos.

Una vez que tengas el deployment funcionando, puedes limpiar el VPC antiguo más tarde con calma.

---

## Verificar el Cambio

Después de cambiar el prefix y hacer "Generate plan", deberías ver en los logs:

```
+ name = "langflow-v2-vpc"  # ✅ Nombre único
```

En lugar de:

```
+ name = "langflow-vpc"  # ❌ Ya existe
```
