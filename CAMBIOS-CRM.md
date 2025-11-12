# 🆕 Cambios: Tabla CRM Automática

## ✅ Resumen

Se agregó configuración automática de una tabla `crm_data` con 30 registros de clientes en cada base de datos PostgreSQL.

---

## 📝 Cambios en `cloud-init.yaml.tpl`

### 1. ✅ Agregado archivo `/root/crm_data.csv` (Línea 14-47)

**Contenido:**
- 30 registros de clientes con datos completos
- Columnas: nombre, documento, edad, estado laboral, ingresos, egresos, productos financieros

**Ejemplo de registro:**
```csv
Camila Lopez;18531599;19;Pensionado;2500;1500;true;true;true;false;true;true;true
```

### 2. ✅ Agregado script `/root/setup-crm-database.sh` (Línea 49-167)

**Funciones:**
- Espera a que PostgreSQL esté listo (`pg_isready`)
- Crea tabla `crm_data` con 14 columnas + id + created_at
- Crea 3 índices para búsquedas rápidas
- Importa datos desde CSV usando `COPY FROM`
- Verifica cantidad de registros importados
- Genera logs en `/var/log/crm-setup.log`

**Tabla creada:**
```sql
CREATE TABLE crm_data (
    id SERIAL PRIMARY KEY,
    nombre_completo TEXT NOT NULL,
    numero_documento BIGINT NOT NULL,
    edad INTEGER NOT NULL,
    estado_laboral TEXT NOT NULL,
    ingreso_mensual INTEGER NOT NULL,
    egresos_mensuales INTEGER NOT NULL,
    tarjeta_de_credito_bronce BOOLEAN NOT NULL,
    tarjeta_de_credito_plata BOOLEAN NOT NULL,
    tarjeta_de_credito_oro BOOLEAN NOT NULL,
    cuenta_ahorros BOOLEAN NOT NULL,
    seguro_mascotas BOOLEAN NOT NULL,
    seguro_desempleo BOOLEAN NOT NULL,
    complemento_medico BOOLEAN NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

**Índices creados:**
```sql
CREATE INDEX idx_crm_numero_documento ON crm_data(numero_documento);
CREATE INDEX idx_crm_estado_laboral ON crm_data(estado_laboral);
CREATE INDEX idx_crm_ingreso ON crm_data(ingreso_mensual);
```

### 3. ✅ Modificado `runcmd` (Línea 361-362)

**Agregado:**
```yaml
# Configurar tabla CRM en PostgreSQL (ejecutar en background)
- nohup /root/setup-crm-database.sh > /var/log/crm-setup.log 2>&1 &
```

**Secuencia de ejecución:**
1. Instalar Podman
2. Descargar imágenes
3. **Ejecutar `/root/start-services.sh`** (inicia PostgreSQL y Langflow)
4. **Ejecutar `/root/setup-crm-database.sh`** (configura tabla CRM) ← NUEVO
5. Ejecutar `/root/configure-api-keys.sh` (configura API_KEY)

### 4. ✅ Actualizado `final_message` (Línea 370)

**Antes:**
```
La configuración de API_KEY se completará en 1-2 minutos
```

**Ahora:**
```
La configuración de API_KEY y tabla CRM se completará en 1-2 minutos
(ver /var/log/api-key-setup.log y /var/log/crm-setup.log)
```

---

## 🎯 Resultado del Deployment

### Cada VSI tendrá:

```
PostgreSQL (127.0.0.1:5432)
├── Database: langflow_db
    ├── Tabla: crm_data (30 registros)
    │   ├── Índice: idx_crm_numero_documento
    │   ├── Índice: idx_crm_estado_laboral
    │   └── Índice: idx_crm_ingreso
    └── Usuario: langflow (con permisos completos)
```

### Logs generados:

```
/var/log/crm-setup.log
├── ✓ PostgreSQL instancia 1 está listo
├── ✓ Tabla crm_data creada exitosamente
├── ✓ Datos CRM importados exitosamente: 30 registros
└── === Configuración de CRM completada ===
```

---

## 🔌 Uso en Langflow

### Credenciales de conexión:

```python
host = "127.0.0.1"
port = 5432
database = "langflow_db"
user = "langflow"
password = "passw0rd"
```

### Query de ejemplo:

```sql
-- Ver todos los clientes
SELECT * FROM crm_data;

-- Buscar por documento
SELECT * FROM crm_data WHERE numero_documento = 18531599;

-- Clientes con alto ingreso
SELECT nombre_completo, ingreso_mensual, estado_laboral
FROM crm_data
WHERE ingreso_mensual > 5000
ORDER BY ingreso_mensual DESC;

-- Estadísticas por estado laboral
SELECT
    estado_laboral,
    COUNT(*) as total,
    AVG(ingreso_mensual) as ingreso_promedio
FROM crm_data
GROUP BY estado_laboral;
```

---

## ⏱️ Tiempo de Setup

**Adicional al deployment:**
- Crear tabla: ~2 segundos
- Importar 30 registros: ~1 segundo
- **Total: ~3 segundos adicionales**

**Timeline completo:**
```
0:00 → cloud-init inicia
0:30 → Podman instalado
2:00 → Imágenes descargadas
3:00 → PostgreSQL iniciando
3:10 → PostgreSQL listo
3:13 → Tabla CRM creada y datos cargados ← NUEVO
3:15 → Langflow iniciando
4:30 → Langflow listo
4:45 → API_KEY configurado
5:00 → Sistema completamente listo ✅
```

---

## ✅ Verificación Post-Deployment

### 1. Verificar logs:

```bash
ssh -i ssh-key-langflow root@<IP>

# Ver log de CRM setup
cat /var/log/crm-setup.log
```

**Salida esperada:**
```
=== Configurando tabla CRM en bases de datos ===
Configurando CRM en PostgreSQL instancia 1 (puerto 5432)...
  ✓ PostgreSQL instancia 1 está listo
  → Creando tabla crm_data...
  ✓ Tabla crm_data creada exitosamente
  → Copiando datos CRM...
  ✓ Datos CRM importados exitosamente:       30 registros
=== Configuración de CRM completada ===
```

### 2. Verificar en PostgreSQL:

```bash
# Contar registros
podman exec postgres-1 psql -U langflow -d langflow_db -c "SELECT COUNT(*) FROM crm_data;"

# Ver estructura de tabla
podman exec postgres-1 psql -U langflow -d langflow_db -c "\d crm_data"

# Ver algunos registros
podman exec postgres-1 psql -U langflow -d langflow_db -c "SELECT nombre_completo, ingreso_mensual FROM crm_data LIMIT 5;"
```

### 3. Verificar en Langflow:

1. Abre Langflow: `http://<IP>:7861`
2. Crea nuevo flow
3. Agrega componente "SQL Database"
4. Configura conexión (127.0.0.1:5432, langflow_db, langflow/passw0rd)
5. Ejecuta query: `SELECT * FROM crm_data LIMIT 5;`
6. Deberías ver los 5 primeros clientes

---

## 🔄 Actualizar Datos CRM

### Para agregar/modificar datos en futuro deployment:

1. **Editar el CSV en cloud-init.yaml.tpl** (Línea 17-46)

2. **Agregar nuevos registros:**
```yaml
      David Patiño;13546408;49;Pensionado;2500;1900;true;true;false;false;true;true;false
      Nuevo Cliente;99999999;30;Empleado;5000;2500;true;false;true;true;false;true;true
```

3. **Commit y redeploy:**
```bash
git add cloud-init.yaml.tpl
git commit -m "Actualizar datos CRM"
git push

# En Schematics:
# Destroy → Pull latest → Apply
```

---

## 📊 Datos Incluidos

### Distribución de Clientes:

| Estado Laboral | Cantidad |
|----------------|----------|
| Empleado | 10 |
| Independiente | 8 |
| Informal | 4 |
| Estudiante | 3 |
| Pensionado | 3 |
| Desempleado | 2 |

### Rangos de Ingreso:

| Rango | Cantidad |
|-------|----------|
| $900 - $2,500 | 21 |
| $3,000 - $5,000 | 5 |
| $5,600 - $8,000 | 3 |
| $12,000+ | 1 |

### Productos Financieros:

| Producto | % Penetración |
|----------|---------------|
| Tarjeta Bronce | 80% |
| Tarjeta Plata | 77% |
| Tarjeta Oro | 80% |
| Cuenta Ahorros | 77% |
| Seguro Mascotas | 77% |
| Seguro Desempleo | 87% |
| Complemento Médico | 83% |

---

## 🎯 Casos de Uso en Langflow

### 1. Asesor Financiero Virtual
```
Usuario: "Busca información del cliente 18531599"
Flow: Query CRM → LLM analiza perfil → Recomienda productos
```

### 2. Análisis de Elegibilidad
```
Input: Documento cliente
Flow: Query CRM → Valida ingresos → Calcula score → Recomienda producto
```

### 3. Segmentación de Clientes
```
Flow: Query CRM (todos) → LLM clasifica por perfil → Genera estrategia marketing
```

### 4. Cross-Selling Inteligente
```
Input: Cliente ID
Flow: Query productos actuales → LLM identifica gaps → Recomienda productos faltantes
```

---

## 🚨 Troubleshooting

### Problema: Tabla no se creó

```bash
# Ver log de errores
cat /var/log/crm-setup.log

# Ejecutar manualmente
/root/setup-crm-database.sh

# Verificar que PostgreSQL esté corriendo
podman ps | grep postgres
```

### Problema: Datos no se importaron

```bash
# Verificar que el CSV existe
cat /root/crm_data.csv

# Verificar permisos
ls -la /root/crm_data.csv

# Reimportar manualmente
podman exec postgres-1 psql -U langflow -d langflow_db -c "DELETE FROM crm_data;"
/root/setup-crm-database.sh
```

---

## 📚 Documentación Creada

- **`CRM-DATABASE-SETUP.md`** - Guía completa de uso de la tabla CRM
- **`CAMBIOS-CRM.md`** - Este archivo (resumen de cambios)

---

## ✅ Checklist de Deployment

- [ ] `cloud-init.yaml.tpl` actualizado con CSV y script
- [ ] Commit realizado
- [ ] Push a GitHub (si aplica)
- [ ] Destroy de deployment anterior
- [ ] Apply plan en Schematics
- [ ] Verificar logs: `/var/log/crm-setup.log`
- [ ] Verificar tabla: `SELECT COUNT(*) FROM crm_data;` → 30
- [ ] Probar query desde Langflow

---

**¡Listo! La tabla CRM se configurará automáticamente en cada nuevo deployment.** 🎉
