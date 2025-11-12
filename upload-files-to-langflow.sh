#!/bin/bash
set -e

INSTANCES=__INSTANCES__
LANGFLOW_BASE_PORT=__LANGFLOW_BASE_PORT__

echo "=== Subiendo archivos .docx a Langflow ===" | tee -a /var/log/file-upload.log

# Lista de archivos a subir
FILES=(
  "ACME_Seguros_Asistencias_Ficticio.docx"
  "ACME_Tarjeta_de_Credito_Ficticio.docx"
  "ACMEPay_Ficticio.docx"
  "CrediACME_Ficticio.docx"
)

# Descargar archivos desde GitHub
echo "Descargando archivos desde GitHub..." | tee -a /var/log/file-upload.log
mkdir -p /root/langflow-files
cd /root/langflow-files

for FILE in "${FILES[@]}"; do
  echo "  → Descargando $FILE..." | tee -a /var/log/file-upload.log
  curl -fsSL "https://raw.githubusercontent.com/Kerath2/langflow-infra/main/$FILE" -o "$FILE"

  if [ $? -eq 0 ]; then
    echo "  ✓ $FILE descargado exitosamente" | tee -a /var/log/file-upload.log
  else
    echo "  ✗ Error al descargar $FILE" | tee -a /var/log/file-upload.log
  fi
done

# Esperar a que Langflow esté listo
echo "Esperando 60 segundos para que Langflow esté completamente listo..." | tee -a /var/log/file-upload.log
sleep 60

# Subir archivos a cada instancia de Langflow
for i in $(seq 1 $INSTANCES); do
  LANGFLOW_PORT=$((LANGFLOW_BASE_PORT + i - 1))

  echo "Subiendo archivos a Langflow instancia $i (puerto $LANGFLOW_PORT)..." | tee -a /var/log/file-upload.log

  # Obtener token
  MAX_RETRIES=10
  RETRY_COUNT=0
  TOKEN=""

  while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    LOGIN_RESPONSE=$(curl -s -X GET "http://127.0.0.1:${LANGFLOW_PORT}/api/v1/auto_login" 2>/dev/null || echo "")

    if [ -n "$LOGIN_RESPONSE" ]; then
      TOKEN=$(echo "$LOGIN_RESPONSE" | grep -o '"access_token":"[^"]*' | cut -d'"' -f4)

      if [ -n "$TOKEN" ]; then
        echo "  ✓ Token obtenido para instancia $i" | tee -a /var/log/file-upload.log
        break
      fi
    fi

    RETRY_COUNT=$((RETRY_COUNT + 1))
    echo "  ⚠ Esperando token (intento $RETRY_COUNT/$MAX_RETRIES)..." | tee -a /var/log/file-upload.log
    sleep 5
  done

  if [ -z "$TOKEN" ]; then
    echo "  ✗ No se pudo obtener token para instancia $i" | tee -a /var/log/file-upload.log
    continue
  fi

  # Subir cada archivo
  for FILE in "${FILES[@]}"; do
    echo "  → Subiendo $FILE a instancia $i..." | tee -a /var/log/file-upload.log

    UPLOAD_RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" -X POST "http://127.0.0.1:${LANGFLOW_PORT}/api/v2/files" \
      -H "Authorization: Bearer $TOKEN" \
      -F "file=@/root/langflow-files/$FILE" 2>/dev/null || echo "")

    HTTP_STATUS=$(echo "$UPLOAD_RESPONSE" | grep "HTTP_STATUS:" | cut -d: -f2)

    if [ "$HTTP_STATUS" = "200" ] || [ "$HTTP_STATUS" = "201" ]; then
      echo "  ✓ $FILE subido exitosamente a instancia $i" | tee -a /var/log/file-upload.log
    else
      echo "  ✗ Error al subir $FILE a instancia $i (HTTP $HTTP_STATUS)" | tee -a /var/log/file-upload.log
    fi

    sleep 1
  done
done

echo "=== Subida de archivos completada ===" | tee -a /var/log/file-upload.log
