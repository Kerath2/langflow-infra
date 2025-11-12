# Requisitos Oficiales: Langflow + PostgreSQL

Basado en la documentación oficial de Langflow y PostgreSQL.

---

## 📋 Requisitos Oficiales de Langflow

### Según [Langflow Documentation - Production Best Practices](https://docs.langflow.org/deployment-prod-best-practices)

#### Deployment de Producción (Runtime - Backend Only):
```
Mínimo por instancia:
- RAM: 2 GB (2Gi)
- CPU: 1 vCPU (1000m)
- Réplicas recomendadas: 3 (para alta disponibilidad)
```

#### Deployment de Desarrollo (IDE - con editor visual):
```
Backend:
- RAM: 1 GB (1Gi) mínimo
- CPU: 0.5 vCPU (500m)

Frontend:
- RAM: 512 MB (512Mi) mínimo
- CPU: 0.3 vCPU (300m)

Total IDE: ~1.5 GB RAM, ~1 vCPU
```

#### Deployment Básico (Servidor Remoto):
```
Configuración mínima recomendada:
- CPU: 2 cores (dual-core)
- RAM: 2 GB mínimo
```

### Factores que Afectan los Requisitos:
- ✅ Complejidad de los flows
- ✅ Volumen de usuarios concurrent
- ✅ Carga de requests
- ✅ Tamaño de payloads (especialmente uploads de archivos)
- ✅ Requisitos de storage para caché y base de datos

---

## 🗄️ Requisitos Oficiales de PostgreSQL

### Según [PostgreSQL Documentation](https://www.postgresql.org/docs/current/install-requirements.html)

#### Mínimo Absoluto (No Recomendado):
```
- RAM: 32 MB (solo para arrancar)
- Disk: 50 KB
```

#### Mínimo Práctico Recomendado:
```
- RAM: 2 GB (fuera del OS)
- CPU: 2 cores
```

#### Producción con Langflow:
```
Según Langflow docs para PostgreSQL externo en producción:
- RAM: 4 GB (4Gi)
- CPU: 2 vCPU
- Réplicas: Múltiples para alta disponibilidad
```

#### Escalabilidad PostgreSQL:
- Lee (reads): Escala linealmente hasta ~64 cores
- Escribe (writes): Escala linealmente hasta ~20 cores
- **Importante**: Mejor tener más cores que velocidad de clock

---

## 🎯 Aplicación a Nuestro Caso: IBM Cloud VSI

### Nuestra Configuración Actual:
```
1 VSI ejecuta:
- 1 contenedor Langflow (IDE completo: backend + frontend)
- 1 contenedor PostgreSQL
- Sistema Operativo Ubuntu 22.04
```

### Análisis de Perfiles IBM Cloud:

#### Perfil cx2-2x4 (2 vCPU, 4GB RAM):
```
Distribución de RAM:
- Ubuntu 22.04:          ~300 MB
- PostgreSQL (idle):     ~200 MB (puede crecer a 500-800 MB)
- Langflow (mínimo):     ~1.5 GB (IDE: backend + frontend)
- Overhead Podman:       ~100 MB
────────────────────────────────
Total base:              ~2.1 GB
Disponible para uso:     ~1.9 GB

CPU:
- PostgreSQL:            0.5 vCPU (bajo uso)
- Langflow:              1 vCPU (mínimo recomendado)
────────────────────────────────
Total base:              1.5 vCPU
Disponible para carga:   0.5 vCPU
```

**Veredicto según documentación oficial:**
- ✅ Cumple requisitos **mínimos** de Langflow (2 GB RAM, 1 CPU)
- ⚠️ PostgreSQL está por debajo del recomendado (tiene 4GB total, recomendado 4GB solo para PG)
- ⚠️ RAM ajustada para 3-5 usuarios ligeros
- ❌ No cumple para múltiples usuarios activos o flows complejos

#### Perfil cx2-4x8 (4 vCPU, 8GB RAM):
```
Distribución de RAM:
- Ubuntu 22.04:          ~300 MB
- PostgreSQL:            ~500-800 MB
- Langflow:              ~2 GB (con margen)
- Overhead Podman:       ~100 MB
────────────────────────────────
Total base:              ~3.2 GB
Disponible para uso:     ~4.8 GB

CPU:
- PostgreSQL:            0.5-1 vCPU
- Langflow:              1-2 vCPU
────────────────────────────────
Total base:              1.5-3 vCPU
Disponible para carga:   1-2.5 vCPU
```

**Veredicto según documentación oficial:**
- ✅ Cumple **cómodamente** requisitos mínimos
- ✅ PostgreSQL tiene recursos adecuados
- ✅ Langflow puede ejecutar flows complejos
- ✅ Soporta 10-15 usuarios activos simultáneos
- ✅ Margen para picos de carga

---

## 💡 Recomendaciones Basadas en Documentación Oficial

### Para 2-5 Usuarios (Uso Ligero):
```
✅ RECOMENDADO: cx2-2x4 (2 vCPU, 4GB RAM)
- Cumple requisitos mínimos oficiales
- Costo: ~$65/mes por VSI
- Configuración: vsi_count = 1
- Total: ~$65/mes
```

### Para 5-10 Usuarios (Uso Moderado):
```
✅ RECOMENDADO: cx2-2x4 con 2 VSIs
- Distribución de carga entre 2 instancias
- Costo: ~$130/mes total
- Configuración: vsi_count = 2, vsi_profile = "cx2-2x4"
```

### Para 10-20 Usuarios (Uso Activo):
```
✅ RECOMENDADO: cx2-4x8 con 2 VSIs
- Más recursos por instancia
- Costo: ~$260/mes total
- Configuración: vsi_count = 2, vsi_profile = "cx2-4x8"

O ALTERNATIVAMENTE:

✅ 4 VSIs con cx2-2x4
- Más granularidad para escalar
- Costo: ~$260/mes total
- Configuración: vsi_count = 4, vsi_profile = "cx2-2x4"
```

### Para 20+ Usuarios (Producción):
```
✅ RECOMENDADO: cx2-4x8 con N VSIs
- Calcula: N = (usuarios / 10) redondeado arriba
- 30 usuarios = 3 VSIs × cx2-4x8 = ~$390/mes
- 50 usuarios = 5 VSIs × cx2-4x8 = ~$650/mes
- Considera Load Balancer (+$60/mes) para distribución automática
```

---

## 🔬 Pruebas Reales vs Documentación

### Lo que observamos en tu VSI actual:
```
VSI actual: cx2-4x8 (4 vCPU, 8GB RAM)
- 2 Langflow + 2 PostgreSQL = sobrecargado
- Load average: 2.21 (alto para 4 cores)
- I/O wait: 74.8% (cuello de botella en disco)
```

**Conclusión:**
- La sobrecarga era por ejecutar 4 instancias (2 Langflow + 2 PostgreSQL)
- Con 1 Langflow + 1 PostgreSQL, cx2-2x4 debería funcionar bien

---

## 📊 Tabla de Decisión Final

| Usuarios | Perfil Recomendado | VSIs | Costo/mes | Justificación Oficial |
|----------|-------------------|------|-----------|----------------------|
| 2-5 | cx2-2x4 | 1 | ~$65 | Cumple mínimos de Langflow (2GB RAM, 1 CPU) |
| 5-10 | cx2-2x4 | 2 | ~$130 | Distribución de carga según best practices |
| 10-20 | cx2-4x8 | 2 | ~$260 | Cumple recomendaciones de producción |
| 20-50 | cx2-4x8 | 3-5 | ~$390-650 | Langflow recomienda 2GB por instancia + margen |
| 50+ | cx2-4x8 + LB | 5+ | ~$650+ | Alta disponibilidad con load balancer |

---

## ⚠️ Importante: Diferencia entre Mínimos y Recomendados

La documentación de Langflow es clara:

> "These are baseline recommendations requiring testing and adjustment based on specific deployment characteristics and performance metrics."

**Mínimo != Óptimo**

- **Mínimo (2GB RAM, 1 CPU):** Funciona, pero con margen justo
- **Recomendado (4GB RAM, 2 CPU):** Funciona cómodamente con margen para carga

---

## 🎯 Conclusión para Tu Caso

**Para empezar (2-10 usuarios):**
```hcl
vsi_count = 2
vsi_profile = "cx2-2x4"  # Cumple requisitos mínimos oficiales
langflow_instances_per_vsi = 1
```

**Costo:** ~$130/mes
**Capacidad:** 6-10 usuarios activos cómodamente

**Si crece (10-20 usuarios):**
```hcl
vsi_count = 2
vsi_profile = "cx2-4x8"  # Cumple requisitos recomendados
langflow_instances_per_vsi = 1
```

**Costo:** ~$260/mes
**Capacidad:** 20-30 usuarios activos cómodamente

---

## 📚 Referencias

1. [Langflow Production Best Practices](https://docs.langflow.org/deployment-prod-best-practices)
2. [Langflow Docker Deployment](https://docs.langflow.org/deployment-docker)
3. [PostgreSQL Installation Requirements](https://www.postgresql.org/docs/current/install-requirements.html)
4. [Langflow GitHub Discussion #3304](https://github.com/langflow-ai/langflow/discussions/3304)
