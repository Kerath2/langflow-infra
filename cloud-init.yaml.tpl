#cloud-config
package_update: true
package_upgrade: true

packages:
  - ca-certificates
  - curl
  - gnupg
  - lsb-release
  - jq
  - openssl

write_files:
  - path: /root/start-services.sh
    permissions: '0755'
    content: |
      #!/bin/bash
      set -e

      INSTANCES=${langflow_instances}
      LANGFLOW_BASE_PORT=${langflow_base_port}
      POSTGRES_BASE_PORT=${postgres_base_port}
      VSI_NAME="${vsi_name}"
      API_KEY="${api_key}"

      echo "Iniciando $INSTANCES instancias de Postgres y $INSTANCES instancias de Langflow en $VSI_NAME..." | tee -a /var/log/services-setup.log

      # Esperar a que Podman esté completamente listo
      sleep 10

      # Iniciar todas las instancias de Postgres
      echo "=== Iniciando instancias de Postgres ===" | tee -a /var/log/services-setup.log
      for i in $(seq 1 $INSTANCES); do
        POSTGRES_CONTAINER="postgres-$${i}"
        POSTGRES_PORT=$((POSTGRES_BASE_PORT + i - 1))
        POSTGRES_VOLUME="pgdata_$${i}"

        # Credenciales de Postgres
        POSTGRES_USER="langflow"
        POSTGRES_PASSWORD="passw0rd"
        POSTGRES_DB="langflow_db"

        echo "Creando volumen: $POSTGRES_VOLUME" | tee -a /var/log/services-setup.log
        podman volume create $POSTGRES_VOLUME

        echo "Iniciando Postgres: $POSTGRES_CONTAINER en puerto $POSTGRES_PORT" | tee -a /var/log/services-setup.log
        podman run -d \
          --name $POSTGRES_CONTAINER \
          -p $POSTGRES_PORT:5432 \
          -e POSTGRES_USER=$POSTGRES_USER \
          -e POSTGRES_PASSWORD=$POSTGRES_PASSWORD \
          -e POSTGRES_DB=$POSTGRES_DB \
          -v $POSTGRES_VOLUME:/var/lib/postgresql/data:Z \
          --restart unless-stopped \
          docker.io/library/postgres:16

        if [ $? -eq 0 ]; then
          echo "✓ Postgres $POSTGRES_CONTAINER iniciado en puerto $POSTGRES_PORT" | tee -a /var/log/services-setup.log
        else
          echo "✗ Error al iniciar $POSTGRES_CONTAINER" | tee -a /var/log/services-setup.log
        fi

        # Guardar credenciales
        echo "Postgres $i - Host: localhost:$POSTGRES_PORT, User: $POSTGRES_USER, DB: $POSTGRES_DB, Password: $POSTGRES_PASSWORD" >> /root/postgres-credentials.txt

        sleep 2
      done

      # Iniciar todas las instancias de Langflow
      echo "=== Iniciando instancias de Langflow ===" | tee -a /var/log/services-setup.log
      for i in $(seq 1 $INSTANCES); do
        LANGFLOW_CONTAINER="langflow-$${i}"
        LANGFLOW_PORT=$((LANGFLOW_BASE_PORT + i - 1))
        LANGFLOW_VOLUME="langflow_data_$${i}"
        POSTGRES_PORT=$((POSTGRES_BASE_PORT + i - 1))

        # Configurar DATABASE_URL para conectar a PostgreSQL
        POSTGRES_USER="langflow"
        POSTGRES_PASSWORD="passw0rd"
        POSTGRES_DB="langflow_db"
        DATABASE_URL="postgresql://$${POSTGRES_USER}:$${POSTGRES_PASSWORD}@localhost:$${POSTGRES_PORT}/$${POSTGRES_DB}"

        echo "Iniciando Langflow: $LANGFLOW_CONTAINER en puerto $LANGFLOW_PORT" | tee -a /var/log/services-setup.log
        podman run -d \
          --name $LANGFLOW_CONTAINER \
          -p $LANGFLOW_PORT:7860 \
          -e LANGFLOW_DATABASE_URL="$DATABASE_URL" \
          -e LANGFLOW_AUTO_LOGIN=true \
          -v $LANGFLOW_VOLUME:/app/langflow \
          --restart unless-stopped \
          docker.io/langflowai/langflow:latest

        if [ $? -eq 0 ]; then
          echo "✓ Langflow $LANGFLOW_CONTAINER iniciado en puerto $LANGFLOW_PORT" | tee -a /var/log/services-setup.log
        else
          echo "✗ Error al iniciar $LANGFLOW_CONTAINER" | tee -a /var/log/services-setup.log
        fi

        sleep 2
      done

      # Verificar contenedores en ejecución
      echo "=== Contenedores en ejecución ===" | tee -a /var/log/services-setup.log
      echo "Postgres ($INSTANCES instancias):" | tee -a /var/log/services-setup.log
      podman ps --filter "name=postgres" | tee -a /var/log/services-setup.log
      echo "" | tee -a /var/log/services-setup.log
      echo "Langflow ($INSTANCES instancias):" | tee -a /var/log/services-setup.log
      podman ps --filter "name=langflow" | tee -a /var/log/services-setup.log

      echo "Configuración completada." | tee -a /var/log/services-setup.log
      echo "Credenciales de Postgres guardadas en /root/postgres-credentials.txt" | tee -a /var/log/services-setup.log

  - path: /root/configure-api-keys.sh
    permissions: '0755'
    content: |
      #!/bin/bash
      set -e

      INSTANCES=${langflow_instances}
      LANGFLOW_BASE_PORT=${langflow_base_port}
      API_KEY="${api_key}"

      echo "=== Configurando variables API_KEY en Langflow ===" | tee -a /var/log/api-key-setup.log

      # Esperar a que las instancias de Langflow estén listas
      echo "Esperando 30 segundos para que Langflow inicie completamente..." | tee -a /var/log/api-key-setup.log
      sleep 30

      # Configurar API_KEY en cada instancia de Langflow
      for i in $(seq 1 $INSTANCES); do
        LANGFLOW_PORT=$((LANGFLOW_BASE_PORT + i - 1))

        echo "Configurando API_KEY en Langflow instancia $i (puerto $LANGFLOW_PORT)..." | tee -a /var/log/api-key-setup.log

        # Intentar obtener token y crear variable (con reintentos)
        MAX_RETRIES=10
        RETRY_COUNT=0
        TOKEN=""

        while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
          # Obtener token via auto_login
          LOGIN_RESPONSE=$$(curl -s -X GET "http://localhost:$${LANGFLOW_PORT}/api/v1/auto_login" 2>/dev/null || echo "")

          if [ -n "$$LOGIN_RESPONSE" ]; then
            TOKEN=$$(echo "$$LOGIN_RESPONSE" | grep -o '"access_token":"[^"]*' | cut -d'"' -f4)

            if [ -n "$$TOKEN" ]; then
              echo "  ✓ Token obtenido para instancia $i" | tee -a /var/log/api-key-setup.log
              break
            fi
          fi

          echo "  ⚠ Esperando a que Langflow instancia $i esté listo (intento $$((RETRY_COUNT + 1))/$$MAX_RETRIES)..." | tee -a /var/log/api-key-setup.log
          sleep 5
          RETRY_COUNT=$$((RETRY_COUNT + 1))
        done

        if [ -z "$$TOKEN" ]; then
          echo "  ✗ No se pudo obtener token para instancia $i" | tee -a /var/log/api-key-setup.log
          continue
        fi

        # Crear la variable global API_KEY
        VARIABLE_RESPONSE=$$(curl -s -w "\nHTTP_STATUS:%{http_code}" -X POST "http://localhost:$${LANGFLOW_PORT}/api/v1/variables/" \
          -H "Content-Type: application/json" \
          -H "Authorization: Bearer $$TOKEN" \
          -d "{\"name\":\"API_KEY\",\"value\":\"$$API_KEY\",\"type\":\"Credential\",\"default_fields\":[\"OpenAI API Key\",\"Anthropic API Key\",\"Google API Key\"]}" 2>/dev/null || echo "")

        HTTP_STATUS=$$(echo "$$VARIABLE_RESPONSE" | grep "HTTP_STATUS:" | cut -d: -f2)

        if [ "$$HTTP_STATUS" = "200" ] || [ "$$HTTP_STATUS" = "201" ]; then
          echo "  ✓ Variable API_KEY creada en Langflow instancia $i" | tee -a /var/log/api-key-setup.log
        elif [ "$$HTTP_STATUS" = "409" ]; then
          echo "  ⚠ Variable API_KEY ya existe en instancia $i" | tee -a /var/log/api-key-setup.log
        else
          echo "  ✗ Error al crear variable en instancia $i (HTTP $$HTTP_STATUS)" | tee -a /var/log/api-key-setup.log
        fi
      done

      echo "=== Configuración de API_KEY completada ===" | tee -a /var/log/api-key-setup.log

runcmd:
  # Instalar Podman
  - apt-get update
  - apt-get install -y podman

  # Habilitar y iniciar el servicio de Podman
  - systemctl enable podman
  - systemctl start podman

  # Verificar instalación de Podman
  - podman --version | tee /var/log/podman-install.log

  # Pre-descargar las imágenes de Postgres y Langflow
  - echo "Descargando imágenes de Postgres y Langflow..." | tee -a /var/log/services-setup.log
  - podman pull docker.io/library/postgres:16
  - podman pull docker.io/langflowai/langflow:latest

  # Ejecutar el script para iniciar los servicios
  - /root/start-services.sh

  # Configurar variables API_KEY en Langflow (ejecutar en background)
  - nohup /root/configure-api-keys.sh > /var/log/api-key-setup.log 2>&1 &

  # Configurar systemd para auto-inicio de contenedores (opcional)
  - systemctl enable podman-restart.service || true

final_message: "Sistema aprovisionado correctamente. ${langflow_instances} instancias de Postgres y ${langflow_instances} instancias de Langflow están ejecutándose. La configuración de API_KEY se completará en 1-2 minutos (ver /var/log/api-key-setup.log)."
