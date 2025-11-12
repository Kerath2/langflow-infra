# Simplificar a 1 VSI con 1 Langflow

## 🎯 Nueva Configuración Recomendada

**Setup Simple para Múltiples Usuarios:**
- ✅ 1 VSI (cx2-2x4: 2 vCPU, 4GB RAM)
- ✅ 1 PostgreSQL
- ✅ 1 Langflow (soporta múltiples usuarios simultáneos)
- ✅ Costo: ~$65/mes (en lugar de $278/mes)

**Una sola instancia de Langflow puede ser usada por múltiples personas al mismo tiempo.**

---

## 📝 Actualizar en IBM Cloud Schematics

### Paso 1: Ir a Settings

1. Ve a tu workspace en Schematics
2. Click en **"Settings"** (menú lateral)
3. Scroll hasta la sección **"Variables"**

### Paso 2: Cambiar las Variables

Cambia estos valores:

| Variable | Valor Actual | Nuevo Valor | Descripción |
|----------|--------------|-------------|-------------|
| `vsi_count` | `2` | **`1`** | Solo 1 máquina virtual |
| `langflow_instances_per_vsi` | `2` | **`1`** | 1 instancia de Langflow |
| `vsi_profile` | `cx2-4x8` | **`cx2-2x4`** | Perfil más económico |

### Paso 3: Aplicar Cambios

**⚠️ IMPORTANTE: Destruye el deployment actual primero**

1. Ve a **"Actions"** → **"Destroy resources"**
2. Espera a que termine (destruirá las 2 VSIs actuales)
3. Luego **"Actions"** → **"Generate plan"**
4. Revisa el plan (debe mostrar 1 VSI, 1 Langflow)
5. **"Apply plan"**

---

## 📊 Comparación: Antes vs Después

### ❌ ANTES (Setup Actual)
- 2 VSIs (cx2-4x8)
- 4 instancias de Langflow (2 por VSI)
- 4 instancias de PostgreSQL
- **Costo: ~$278/mes**
- **Uso de RAM: ~16GB total**

### ✅ DESPUÉS (Setup Simplificado)
- 1 VSI (cx2-2x4)
- 1 instancia de Langflow (múltiples usuarios)
- 1 instancia de PostgreSQL
- **Costo: ~$65/mes**
- **Uso de RAM: ~4GB total**
- **Ahorro: ~$213/mes (77%)**

---

## 🌐 Acceso Después del Deployment

Con la nueva configuración tendrás:

```
http://<NUEVA_IP>:7861  # Una sola URL para todos los usuarios
```

**Múltiples usuarios pueden:**
- ✅ Conectarse simultáneamente
- ✅ Crear sus propios flows
- ✅ Compartir flows entre sí
- ✅ Usar la misma variable API_KEY

---

## 🔄 Alternativa: Actualizar sin Destruir (Avanzado)

Si NO quieres destruir y recrear:

1. En Schematics → Settings → Variables
2. Cambia `vsi_count` de `2` a `1`
3. Cambia `langflow_instances_per_vsi` de `2` a `1`
4. **NO cambies** `vsi_profile` (mantén cx2-4x8)
5. Generate plan → Apply

Esto:
- ✅ Eliminará la segunda VSI
- ✅ Recreará la primera VSI con 1 instancia
- ⚠️ Perderás los flows guardados en las VSIs actuales

---

## 💾 Backup (Opcional)

Si tienes flows importantes guardados, antes de destruir:

```bash
# Conectarte a la VSI actual
ssh -i ssh-key-langflow root@52.118.151.6

# Exportar volúmenes de Langflow
podman volume export langflow_data_1 -o /root/langflow_backup_1.tar
podman volume export langflow_data_2 -o /root/langflow_backup_2.tar

# Copiar a tu Mac
scp -i ssh-key-langflow root@52.118.151.6:/root/langflow_backup_*.tar ./
```

Después del nuevo deployment:
```bash
# Restaurar en la nueva VSI
scp -i ssh-key-langflow langflow_backup_1.tar root@<NUEVA_IP>:/root/
ssh -i ssh-key-langflow root@<NUEVA_IP>
podman volume import langflow_data_1 /root/langflow_backup_1.tar
podman restart langflow-1
```

---

## ✅ Verificación Post-Deployment

Después de aplicar los cambios:

1. **Verifica en Outputs** que solo haya 1 IP
2. **Accede a** `http://<IP>:7861`
3. **Verifica API_KEY** en Settings → Global Variables
4. **Costo estimado** debe ser ~$65/mes

---

## 📈 Escalar Después (Si necesitas)

Si más adelante necesitas más capacidad:

1. Cambiar `vsi_profile` a `cx2-4x8` (más RAM/CPU)
2. Agregar más VSIs (`vsi_count = 2`)
3. Agregar load balancer para distribuir tráfico

Pero para empezar, **1 VSI con 1 Langflow es suficiente** para múltiples usuarios.
