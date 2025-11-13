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
  - git

write_files:
  - path: /root/crm_data.csv
    permissions: '0644'
    encoding: utf-8
    content: |
      nombre_completo;numero_documento;edad;estado_laboral;ingreso_mensual;egresos_mensuales;tarjeta_de_credito_bronce;tarjeta_de_credito_plata;tarjeta_de_credito_oro;cuenta_ahorros;seguro_mascotas;seguro_desempleo;complemento_medico
      Camila Lopez;18531599;19;Pensionado;2500;1500;true;true;true;false;true;true;true
      Alejandra Prieto;10133530;32;Empleado;2500;2000;true;false;true;true;true;true;true
      Daniela Rincon;61617074;69;Empleado;2500;2200;true;true;true;true;true;true;true
      Monica Alvarez;75715932;47;Empleado;2500;1800;false;false;true;true;true;true;true
      Ana Martinez;11620162;32;Estudiante;2500;1900;true;true;false;true;false;true;false
      Esteban Quintero;27053089;41;Informal;2500;1500;false;true;true;true;true;true;true
      Diana Morales;14437506;61;Empleado;2500;2000;true;true;false;false;false;false;false
      Tatiana Beltran;25549169;66;Estudiante;5600;2200;true;true;true;true;true;true;true
      Paula Rojas;11710367;26;Informal;2500;1800;true;true;true;false;true;false;true
      Felipe Castro;29020625;55;Independiente;3500;1900;true;false;true;true;true;true;true
      Santiago Herrera;24541466;68;Independiente;1800;1500;false;true;true;true;true;true;true
      Laura Torres;35035035;45;Empleado;8000;2000;true;false;false;true;true;true;true
      Marcela Leon;89646901;34;Empleado;1800;2200;false;true;true;true;false;true;true
      Oscar Lozano;11838767;51;Empleado;12000;1800;true;true;false;false;true;true;true
      Mateo Suarez;13273528;51;Independiente;1800;1900;true;true;true;true;false;false;true
      Pilar Mejia;12762427;31;Empleado;3500;1500;true;true;true;false;true;true;true
      Viviana Duarte;10204122;24;Independiente;1200;2000;true;true;true;true;true;false;false
      Nicolas Molina;12480633;45;Informal;3500;2200;false;false;true;true;true;true;true
      Luz Daza;10493988;27;Independiente;900;1800;true;true;true;true;true;true;false
      Andres Garcia;39016698;44;Estudiante;2500;1900;false;false;false;true;true;true;true
      Sebastian Vega;11728784;32;Empleado;1800;1500;true;true;true;true;true;true;true
      Luis Fernandez;12705329;56;Informal;2500;2000;true;true;false;false;true;true;true
      Hernan Cardenas;97559056;22;Empleado;1800;2200;true;true;true;true;false;true;true
      Natalia Jimenez;13481931;57;Desempleado;8000;1800;true;true;true;false;true;true;true
      Carlos Rodriguez;16556640;36;Independiente;8000;1900;false;true;true;true;false;false;true
      Valentina Ortiz;68744720;63;Empleado;5000;1500;true;false;true;true;true;true;true
      Javier Ramirez;52723624;69;Independiente;2500;2000;false;true;true;true;true;false;true
      Ricardo Silva;72078781;35;Independiente;5000;2200;true;false;false;true;true;true;false
      Julian Castano;90158223;44;Empleado;2500;1800;true;true;true;true;true;true;true
      David Patino;13546408;49;Pensionado;2500;1900;true;true;false;false;true;true;false

  - path: /root/setup-crm-database.sh
    permissions: '0755'
    content: |
      #!/bin/bash
      set -e

      INSTANCES=${langflow_instances}
      POSTGRES_BASE_PORT=${postgres_base_port}

      echo "=== Configurando tabla CRM en bases de datos ===" | tee -a /var/log/crm-setup.log

      # Configurar CRM table en cada instancia de PostgreSQL
      for i in $(seq 1 $INSTANCES); do
        POSTGRES_PORT=$((POSTGRES_BASE_PORT + i - 1))
        POSTGRES_CONTAINER="postgres-$${i}"

        echo "Configurando CRM en PostgreSQL instancia $i (puerto $POSTGRES_PORT)..." | tee -a /var/log/crm-setup.log

        # Esperar a que PostgreSQL esté listo
        MAX_RETRIES=10
        RETRY_COUNT=0

        while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
          if podman exec $POSTGRES_CONTAINER pg_isready -U langflow > /dev/null 2>&1; then
            echo "  ✓ PostgreSQL instancia $i está listo" | tee -a /var/log/crm-setup.log
            break
          fi

          echo "  ⚠ Esperando a que PostgreSQL instancia $i esté listo (intento $((RETRY_COUNT + 1))/$MAX_RETRIES)..." | tee -a /var/log/crm-setup.log
          sleep 3
          RETRY_COUNT=$((RETRY_COUNT + 1))
        done

        if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
          echo "  ✗ PostgreSQL instancia $i no respondió" | tee -a /var/log/crm-setup.log
          continue
        fi

        # Crear esquema CRM separado para evitar conflictos con Alembic de Langflow
        echo "  → Creando esquema CRM..." | tee -a /var/log/crm-setup.log
        podman exec $POSTGRES_CONTAINER psql -U langflow -d langflow_db -c "CREATE SCHEMA IF NOT EXISTS crm;"
        podman exec $POSTGRES_CONTAINER psql -U langflow -d langflow_db -c "GRANT ALL ON SCHEMA crm TO langflow;"

        # Crear la tabla crm_data en el esquema crm
        echo "  → Creando tabla crm.crm_data..." | tee -a /var/log/crm-setup.log
        podman exec $POSTGRES_CONTAINER psql -U langflow -d langflow_db -c "CREATE TABLE IF NOT EXISTS crm.crm_data (numero_documento BIGINT PRIMARY KEY, nombre_completo TEXT NOT NULL, edad INTEGER NOT NULL, estado_laboral TEXT NOT NULL, ingreso_mensual INTEGER NOT NULL, egresos_mensuales INTEGER NOT NULL, tarjeta_de_credito_bronce BOOLEAN NOT NULL, tarjeta_de_credito_plata BOOLEAN NOT NULL, tarjeta_de_credito_oro BOOLEAN NOT NULL, cuenta_ahorros BOOLEAN NOT NULL, seguro_mascotas BOOLEAN NOT NULL, seguro_desempleo BOOLEAN NOT NULL, complemento_medico BOOLEAN NOT NULL);"
        podman exec $POSTGRES_CONTAINER psql -U langflow -d langflow_db -c "CREATE INDEX IF NOT EXISTS idx_crm_estado_laboral ON crm.crm_data(estado_laboral);"
        podman exec $POSTGRES_CONTAINER psql -U langflow -d langflow_db -c "CREATE INDEX IF NOT EXISTS idx_crm_ingreso ON crm.crm_data(ingreso_mensual);"
        podman exec $POSTGRES_CONTAINER psql -U langflow -d langflow_db -c "GRANT ALL PRIVILEGES ON TABLE crm.crm_data TO langflow;"

        if [ $? -eq 0 ]; then
          echo "  ✓ Tabla crm_data creada exitosamente" | tee -a /var/log/crm-setup.log
        else
          echo "  ✗ Error al crear tabla crm_data" | tee -a /var/log/crm-setup.log
          continue
        fi

        # Copiar CSV al contenedor con verificación
        echo "  → Copiando datos CRM..." | tee -a /var/log/crm-setup.log
        if ! podman cp /root/crm_data.csv $POSTGRES_CONTAINER:/tmp/crm_data.csv; then
          echo "  ✗ Error al copiar CSV al contenedor" | tee -a /var/log/crm-setup.log
          continue
        fi

        # Verificar que el archivo se copió correctamente
        if ! podman exec $POSTGRES_CONTAINER test -f /tmp/crm_data.csv; then
          echo "  ✗ CSV no encontrado en el contenedor" | tee -a /var/log/crm-setup.log
          continue
        fi

        echo "  ✓ CSV copiado exitosamente" | tee -a /var/log/crm-setup.log

        # Importar datos desde CSV con codificación UTF-8 explícita
        echo "  → Importando datos desde CSV..." | tee -a /var/log/crm-setup.log
        podman exec $POSTGRES_CONTAINER psql -U langflow -d langflow_db -c "SET client_encoding = 'UTF8'; COPY crm.crm_data (nombre_completo, numero_documento, edad, estado_laboral, ingreso_mensual, egresos_mensuales, tarjeta_de_credito_bronce, tarjeta_de_credito_plata, tarjeta_de_credito_oro, cuenta_ahorros, seguro_mascotas, seguro_desempleo, complemento_medico) FROM '/tmp/crm_data.csv' WITH (FORMAT CSV, DELIMITER ';', HEADER true, ENCODING 'UTF8');"

        if [ $? -eq 0 ]; then
          # Verificar cuántos registros se importaron
          RECORD_COUNT=$(podman exec $POSTGRES_CONTAINER psql -U langflow -d langflow_db -t -c "SELECT COUNT(*) FROM crm.crm_data;")
          echo "  ✓ Datos CRM importados exitosamente: $RECORD_COUNT registros" | tee -a /var/log/crm-setup.log
        else
          echo "  ✗ Error al importar datos CRM" | tee -a /var/log/crm-setup.log
        fi

        # Limpiar archivo temporal
        podman exec $POSTGRES_CONTAINER rm -f /tmp/crm_data.csv

        sleep 1
      done

      echo "=== Configuración de CRM completada ===" | tee -a /var/log/crm-setup.log

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
          --network host \
          -e POSTGRES_USER=$POSTGRES_USER \
          -e POSTGRES_PASSWORD=$POSTGRES_PASSWORD \
          -e POSTGRES_DB=$POSTGRES_DB \
          -e PGPORT=$POSTGRES_PORT \
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
        # Usar 127.0.0.1 en lugar de localhost para evitar problemas de resolución DNS
        POSTGRES_USER="langflow"
        POSTGRES_PASSWORD="passw0rd"
        POSTGRES_DB="langflow_db"
        DATABASE_URL="postgresql://$${POSTGRES_USER}:$${POSTGRES_PASSWORD}@127.0.0.1:$${POSTGRES_PORT}/$${POSTGRES_DB}"

        echo "Iniciando Langflow: $LANGFLOW_CONTAINER en puerto $LANGFLOW_PORT" | tee -a /var/log/services-setup.log
        podman run -d \
          --name $LANGFLOW_CONTAINER \
          --network host \
          -e LANGFLOW_DATABASE_URL="$DATABASE_URL" \
          -e LANGFLOW_AUTO_LOGIN=true \
          -e LANGFLOW_HOST=0.0.0.0 \
          -e LANGFLOW_PORT=$LANGFLOW_PORT \
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

  # Configurar tabla CRM en PostgreSQL (ejecutar en background)
  - nohup /root/setup-crm-database.sh > /var/log/crm-setup.log 2>&1 &

  # Descargar script configure-api-keys.sh desde el repositorio main
  - curl -fsSL https://raw.githubusercontent.com/Kerath2/langflow-infra/main/configure-api-keys.sh -o /root/configure-api-keys.sh.tpl

  # Procesar template con valores reales
  - sed -e 's/__INSTANCES__/${langflow_instances}/g' -e 's/__LANGFLOW_BASE_PORT__/${langflow_base_port}/g' -e 's/__POSTGRES_BASE_PORT__/${postgres_base_port}/g' -e 's/__API_KEY__/${api_key}/g' /root/configure-api-keys.sh.tpl > /root/configure-api-keys.sh
  - chmod +x /root/configure-api-keys.sh

  # Configurar variables API_KEY y DB_URI en Langflow (ejecutar en background)
  - nohup /root/configure-api-keys.sh > /var/log/api-key-setup.log 2>&1 &

  # Descargar script upload-files-to-langflow.sh desde el repositorio main
  - curl -fsSL https://raw.githubusercontent.com/Kerath2/langflow-infra/main/upload-files-to-langflow.sh -o /root/upload-files-to-langflow.sh.tpl

  # Procesar template con valores reales
  - sed -e 's/__INSTANCES__/${langflow_instances}/g' -e 's/__LANGFLOW_BASE_PORT__/${langflow_base_port}/g' /root/upload-files-to-langflow.sh.tpl > /root/upload-files-to-langflow.sh
  - chmod +x /root/upload-files-to-langflow.sh

  # Subir archivos .docx a Langflow (ejecutar en background)
  - nohup /root/upload-files-to-langflow.sh > /var/log/file-upload.log 2>&1 &

  # Configurar systemd para auto-inicio de contenedores (opcional)
  - systemctl enable podman-restart.service || true

final_message: "Sistema aprovisionado correctamente. ${langflow_instances} instancias de Postgres y ${langflow_instances} instancias de Langflow están ejecutándose. La configuración de variables (API_KEY, DB_URI), tabla CRM y archivos .docx se completará en 2-3 minutos (ver logs en /var/log/)."
