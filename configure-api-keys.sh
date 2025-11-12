#!/bin/bash
set -e

INSTANCES=__INSTANCES__
LANGFLOW_BASE_PORT=__LANGFLOW_BASE_PORT__
POSTGRES_BASE_PORT=__POSTGRES_BASE_PORT__
API_KEY="__API_KEY__"

echo "=== Configurando variables en Langflow ===" | tee -a /var/log/api-key-setup.log

# Obtener IP pública de la VSI
echo "Obteniendo IP pública..." | tee -a /var/log/api-key-setup.log
PUBLIC_IP=$(curl -s ifconfig.me || curl -s icanhazip.com || echo "127.0.0.1")
echo "IP pública detectada: $PUBLIC_IP" | tee -a /var/log/api-key-setup.log

# Esperar a que las instancias de Langflow estén listas
echo "Esperando 30 segundos para que Langflow inicie completamente..." | tee -a /var/log/api-key-setup.log
sleep 30

# Configurar variables en cada instancia de Langflow
for i in $(seq 1 $INSTANCES); do
  LANGFLOW_PORT=$((LANGFLOW_BASE_PORT + i - 1))
  POSTGRES_PORT=$((POSTGRES_BASE_PORT + i - 1))

  echo "Configurando API_KEY en Langflow instancia $i (puerto $LANGFLOW_PORT)..." | tee -a /var/log/api-key-setup.log

  # Intentar obtener token y crear variable (con reintentos)
  MAX_RETRIES=10
  RETRY_COUNT=0
  TOKEN=""

  while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    # Obtener token via auto_login
    LOGIN_RESPONSE=$(curl -s -X GET "http://127.0.0.1:${LANGFLOW_PORT}/api/v1/auto_login" 2>/dev/null || echo "")

    if [ -n "$LOGIN_RESPONSE" ]; then
      TOKEN=$(echo "$LOGIN_RESPONSE" | grep -o '"access_token":"[^"]*' | cut -d'"' -f4)

      if [ -n "$TOKEN" ]; then
        echo "  ✓ Token obtenido para instancia $i" | tee -a /var/log/api-key-setup.log
        break
      fi
    fi

    RETRY_COUNT=$((RETRY_COUNT + 1))
    echo "  ⚠ Esperando a que Langflow instancia $i esté listo (intento $RETRY_COUNT/$MAX_RETRIES)..." | tee -a /var/log/api-key-setup.log
    sleep 5
  done

  if [ -z "$TOKEN" ]; then
    echo "  ✗ No se pudo obtener token para instancia $i" | tee -a /var/log/api-key-setup.log
    continue
  fi

  # Crear la variable global API_KEY
  echo "  → Creando variable API_KEY..." | tee -a /var/log/api-key-setup.log
  VARIABLE_RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" -X POST "http://127.0.0.1:${LANGFLOW_PORT}/api/v1/variables/" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $TOKEN" \
    -d "{\"name\":\"API_KEY\",\"value\":\"$API_KEY\",\"type\":\"Credential\",\"default_fields\":[\"OpenAI API Key\",\"Anthropic API Key\",\"Google API Key\"]}" 2>/dev/null || echo "")

  HTTP_STATUS=$(echo "$VARIABLE_RESPONSE" | grep "HTTP_STATUS:" | cut -d: -f2)

  if [ "$HTTP_STATUS" = "200" ] || [ "$HTTP_STATUS" = "201" ]; then
    echo "  ✓ Variable API_KEY creada en Langflow instancia $i" | tee -a /var/log/api-key-setup.log
  elif [ "$HTTP_STATUS" = "409" ]; then
    echo "  ⚠ Variable API_KEY ya existe en instancia $i" | tee -a /var/log/api-key-setup.log
  else
    echo "  ✗ Error al crear variable API_KEY en instancia $i (HTTP $HTTP_STATUS)" | tee -a /var/log/api-key-setup.log
  fi

  # Crear la variable global bd_url (URL de conexión a PostgreSQL con schema CRM)
  BD_URL="postgresql://langflow:passw0rd@${PUBLIC_IP}:${POSTGRES_PORT}/langflow_db?options=-csearch_path=crm"
  echo "  → Creando variable bd_url: $BD_URL" | tee -a /var/log/api-key-setup.log

  BD_URL_RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" -X POST "http://127.0.0.1:${LANGFLOW_PORT}/api/v1/variables/" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $TOKEN" \
    -d "{\"name\":\"bd_url\",\"value\":\"$BD_URL\",\"type\":\"Generic\"}" 2>/dev/null || echo "")

  BD_URL_HTTP_STATUS=$(echo "$BD_URL_RESPONSE" | grep "HTTP_STATUS:" | cut -d: -f2)

  if [ "$BD_URL_HTTP_STATUS" = "200" ] || [ "$BD_URL_HTTP_STATUS" = "201" ]; then
    echo "  ✓ Variable bd_url creada en Langflow instancia $i" | tee -a /var/log/api-key-setup.log
  elif [ "$BD_URL_HTTP_STATUS" = "409" ]; then
    echo "  ⚠ Variable bd_url ya existe en instancia $i" | tee -a /var/log/api-key-setup.log
  else
    echo "  ✗ Error al crear variable bd_url en instancia $i (HTTP $BD_URL_HTTP_STATUS)" | tee -a /var/log/api-key-setup.log
  fi
done

echo "=== Configuración de variables completada ===" | tee -a /var/log/api-key-setup.log
