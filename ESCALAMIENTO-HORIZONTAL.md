# Escalamiento Horizontal: De 2 a N VSIs

## 🎯 Arquitectura Escalable

Cada VSI es **independiente y auto-contenida**:

```
┌─────────────────────┐  ┌─────────────────────┐  ┌─────────────────────┐
│  VSI-1              │  │  VSI-2              │  │  VSI-N              │
│  IP: 52.118.151.6   │  │  IP: 52.118.151.7   │  │  IP: 52.118.151.X   │
├─────────────────────┤  ├─────────────────────┤  ├─────────────────────┤
│ PostgreSQL (5432)   │  │ PostgreSQL (5432)   │  │ PostgreSQL (5432)   │
│ Langflow (7861)     │  │ Langflow (7861)     │  │ Langflow (7861)     │
│                     │  │                     │  │                     │
│ API_KEY configurado │  │ API_KEY configurado │  │ API_KEY configurado │
└─────────────────────┘  └─────────────────────┘  └─────────────────────┘
        ↓                         ↓                         ↓
  Múltiples usuarios        Múltiples usuarios        Múltiples usuarios
```

**Cada Langflow:**
- ✅ Soporta múltiples usuarios simultáneos
- ✅ Los usuarios pueden ver/editar flows de otros (en la misma instancia)
- ✅ Tiene su propia base de datos PostgreSQL
- ✅ Es completamente independiente de otras VSIs

---

## 🚀 Cómo Escalar

### Escenario 1: Tienes 2 VSIs, quieres 10

**En IBM Cloud Schematics:**

1. Ve a tu workspace → **Settings** → **Variables**
2. Busca `vsi_count` y cámbialo de `2` a `10`
3. Click en **"Save"**
4. Ve a **Actions** → **"Generate plan"**
5. Revisa el plan (debe mostrar "8 to add")
6. Click en **"Apply plan"**
7. Espera 10-15 minutos

**Resultado:**
- ✅ Se crearán 8 VSIs adicionales (total: 10)
- ✅ Cada una con Langflow + PostgreSQL
- ✅ Cada una con su IP pública
- ✅ API_KEY pre-configurado en todas

---

### Escenario 2: Tienes 10 VSIs, quieres reducir a 5

1. Cambia `vsi_count` de `10` a `5`
2. **Generate plan** → **Apply plan**
3. Se eliminarán las últimas 5 VSIs (VSI-6 a VSI-10)

⚠️ **ADVERTENCIA:** Se perderán los flows guardados en las VSIs eliminadas.

---

### Escenario 3: Necesitas más recursos por VSI

Si una VSI se queda sin recursos (mucha carga):

1. Cambia `vsi_profile` de `cx2-2x4` a `cx2-4x8`
2. **Generate plan** → **Apply plan**
3. **Esto recreará todas las VSIs** con más CPU/RAM

⚠️ **ADVERTENCIA:** Se perderán los flows guardados. Mejor opción: agregar más VSIs.

---

## 📊 Planificación de Capacidad

### ¿Cuántas VSIs necesito?

**Usuarios simultáneos por Langflow:**
- cx2-2x4 (2 vCPU, 4GB RAM): ~5-10 usuarios activos
- cx2-4x8 (4 vCPU, 8GB RAM): ~10-20 usuarios activos

**Ejemplo: 50 usuarios**
- Con cx2-2x4: 50 / 5 = **10 VSIs mínimo**
- Con cx2-4x8: 50 / 10 = **5 VSIs mínimo**

**Recomendación:** Empieza con pocas VSIs y escala según necesidad.

---

## 💰 Cálculo de Costos

| VSIs | Perfil | CPU Total | RAM Total | Costo/mes |
|------|--------|-----------|-----------|-----------|
| 2 | cx2-2x4 | 4 vCPU | 8 GB | ~$130 |
| 5 | cx2-2x4 | 10 vCPU | 20 GB | ~$325 |
| 10 | cx2-2x4 | 20 vCPU | 40 GB | ~$650 |
| 2 | cx2-4x8 | 8 vCPU | 16 GB | ~$260 |
| 5 | cx2-4x8 | 20 vCPU | 40 GB | ~$650 |
| 10 | cx2-4x8 | 40 vCPU | 80 GB | ~$1,300 |

**Costo base de red (VPC, IPs, etc.):** ~$10-20/mes adicional

---

## 🔄 Distribución de Usuarios

Con múltiples VSIs, tienes opciones para distribuir usuarios:

### Opción 1: Manual
Asigna usuarios a URLs específicas:
- Equipo A → `http://52.118.151.6:7861`
- Equipo B → `http://52.118.151.7:7861`
- Equipo C → `http://52.118.151.8:7861`

### Opción 2: Load Balancer (Avanzado)
Crea un IBM Cloud Load Balancer que distribuya tráfico automáticamente entre las VSIs.

**Ventajas:**
- URL única para todos: `http://langflow.tudominio.com`
- Distribución automática de carga
- Alta disponibilidad (si una VSI falla, redirige a otra)

**Costo adicional:** ~$60-100/mes

---

## 📈 Estrategias de Escalamiento

### Escalamiento Vertical (Más recursos por VSI)
❌ **No recomendado** - Requiere recrear VSIs (pérdida de datos)
- Cambiar `vsi_profile`

### Escalamiento Horizontal (Más VSIs) ✅
✅ **RECOMENDADO** - Sin downtime ni pérdida de datos
- Cambiar `vsi_count`

### Ejemplo de Crecimiento:

```
Mes 1: 2 VSIs (10 usuarios) → $130/mes
Mes 2: 5 VSIs (25 usuarios) → $325/mes
Mes 3: 10 VSIs (50 usuarios) → $650/mes
Mes 6: 20 VSIs (100 usuarios) → $1,300/mes
```

---

## 🛠️ Comandos Útiles

### Ver todas las IPs de tus VSIs

```bash
# En Schematics → Outputs
vsi_public_ips = [
  "52.118.151.6",
  "52.118.151.7",
  "52.118.151.8",
  ...
]
```

### Conectarse a una VSI específica

```bash
ssh -i ssh-key-langflow root@52.118.151.6  # VSI-1
ssh -i ssh-key-langflow root@52.118.151.7  # VSI-2
```

### Ver estado de contenedores en una VSI

```bash
ssh -i ssh-key-langflow root@52.118.151.6
podman ps
podman logs langflow-1
```

---

## 🎯 Buenas Prácticas

1. **Empieza pequeño:** 2 VSIs para probar
2. **Monitorea uso:** Conecta a VSIs y ejecuta `top`, `free -h`
3. **Escala incrementalmente:** No saltes de 2 a 100 VSIs
4. **Documenta asignaciones:** Qué equipo usa qué VSI
5. **Backup periódico:** Exporta flows importantes
6. **Considera Load Balancer:** Para 10+ VSIs

---

## ❓ FAQ

### ¿Puedo tener VSIs en diferentes regiones?
No con esta configuración. Todas las VSIs están en la misma región/zona. Para multi-región, necesitas múltiples workspaces.

### ¿Las VSIs se comunican entre sí?
No, cada VSI es independiente. Los flows y datos NO se comparten entre VSIs.

### ¿Puedo escalar a 100 VSIs?
Sí, el código soporta hasta 100 VSIs. Considera:
- Costo: ~$6,500/mes
- Límites de IBM Cloud (quotas)
- Gestión operativa

### ¿Cómo hago backup antes de escalar?
Ver [TROUBLESHOOTING.md](TROUBLESHOOTING.md) sección "Backup de Flows".

---

## 📞 Monitoreo

Para monitorear tus VSIs:

```bash
# Script para verificar todas las VSIs
for ip in 52.118.151.6 52.118.151.7 52.118.151.8; do
  echo "=== Verificando $ip ==="
  curl -s "http://$ip:7861" > /dev/null && echo "✓ OK" || echo "✗ FAIL"
done
```

---

**TL;DR:** Para escalar de 2 a 10 VSIs, solo cambia `vsi_count = 10` en Schematics y aplica. Cada VSI cuesta ~$65/mes.
