#!/bin/bash

# Script para encontrar y eliminar el VPC "langflow-vpc" fantasma

set -e

echo "🔍 Buscando VPC 'langflow-vpc' en IBM Cloud..."
echo ""

# Verificar si ibmcloud CLI está instalado
if ! command -v ibmcloud &> /dev/null; then
    echo "❌ IBM Cloud CLI no está instalado."
    echo "Instálalo desde: https://cloud.ibm.com/docs/cli?topic=cli-install-ibmcloud-cli"
    exit 1
fi

# Verificar si está logueado
if ! ibmcloud target &> /dev/null; then
    echo "❌ No estás logueado en IBM Cloud."
    echo "Ejecuta: ibmcloud login --sso"
    exit 1
fi

echo "✓ Conectado a IBM Cloud"
echo ""

# Buscar el VPC en la región us-south
echo "Buscando VPCs en región us-south..."
ibmcloud target -r us-south

VPC_LIST=$(ibmcloud is vpcs --output json 2>/dev/null || echo "[]")

# Buscar el VPC con nombre "langflow-vpc"
VPC_ID=$(echo "$VPC_LIST" | jq -r '.[] | select(.name == "langflow-vpc") | .id' 2>/dev/null || echo "")

if [ -z "$VPC_ID" ]; then
    echo "✓ No se encontró VPC 'langflow-vpc' en us-south"
    echo ""
    echo "Buscando en todas las regiones..."

    # Buscar en todas las regiones
    for region in us-south us-east eu-de eu-gb jp-tok jp-osa au-syd ca-tor br-sao; do
        echo "  Verificando región: $region"
        ibmcloud target -r $region &> /dev/null
        VPC_LIST=$(ibmcloud is vpcs --output json 2>/dev/null || echo "[]")
        VPC_ID=$(echo "$VPC_LIST" | jq -r '.[] | select(.name == "langflow-vpc") | .id' 2>/dev/null || echo "")

        if [ -n "$VPC_ID" ]; then
            echo "  ✓ Encontrado en región: $region"
            break
        fi
    done
fi

if [ -z "$VPC_ID" ]; then
    echo ""
    echo "❌ No se encontró ningún VPC con nombre 'langflow-vpc' en ninguna región."
    echo ""
    echo "Posibles razones:"
    echo "1. El VPC está en un resource group al que no tienes acceso"
    echo "2. El VPC ya fue eliminado pero Schematics no actualizó su estado"
    echo "3. Hay un problema de propagación en IBM Cloud"
    echo ""
    echo "SOLUCIÓN RECOMENDADA:"
    echo "Cambia el prefix en Schematics a 'langflow-v2' para usar nombres únicos."
    exit 1
fi

echo ""
echo "✓ VPC encontrado:"
echo "  ID: $VPC_ID"
echo "  Nombre: langflow-vpc"
echo ""

# Buscar recursos dependientes
echo "Buscando recursos dependientes..."
echo ""

# Subnets
SUBNETS=$(ibmcloud is subnets --output json 2>/dev/null | jq -r --arg vpc_id "$VPC_ID" '.[] | select(.vpc.id == $vpc_id) | .id' || echo "")
SUBNET_COUNT=$(echo "$SUBNETS" | grep -v '^$' | wc -l | tr -d ' ')

echo "  Subnets: $SUBNET_COUNT"

# Security Groups
SGS=$(ibmcloud is security-groups --output json 2>/dev/null | jq -r --arg vpc_id "$VPC_ID" '.[] | select(.vpc.id == $vpc_id) | .id' || echo "")
SG_COUNT=$(echo "$SGS" | grep -v '^$' | wc -l | tr -d ' ')

echo "  Security Groups: $SG_COUNT"

# Public Gateways
PGWs=$(ibmcloud is public-gateways --output json 2>/dev/null | jq -r --arg vpc_id "$VPC_ID" '.[] | select(.vpc.id == $vpc_id) | .id' || echo "")
PGW_COUNT=$(echo "$PGWs" | grep -v '^$' | wc -l | tr -d ' ')

echo "  Public Gateways: $PGW_COUNT"

echo ""
echo "⚠️  ADVERTENCIA: Se eliminarán los siguientes recursos:"
echo "  - VPC: langflow-vpc ($VPC_ID)"
echo "  - $SUBNET_COUNT subnets"
echo "  - $SG_COUNT security groups"
echo "  - $PGW_COUNT public gateways"
echo ""
read -p "¿Continuar con la eliminación? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "Operación cancelada."
    exit 0
fi

echo ""
echo "Eliminando recursos..."

# Eliminar subnets
if [ -n "$SUBNETS" ]; then
    echo "Eliminando subnets..."
    for subnet_id in $SUBNETS; do
        echo "  Eliminando subnet: $subnet_id"
        ibmcloud is subnet-delete $subnet_id --force &> /dev/null || true
    done
    sleep 5
fi

# Eliminar public gateways
if [ -n "$PGWs" ]; then
    echo "Eliminando public gateways..."
    for pgw_id in $PGWs; do
        echo "  Eliminando public gateway: $pgw_id"
        ibmcloud is public-gateway-delete $pgw_id --force &> /dev/null || true
    done
    sleep 5
fi

# Eliminar security groups (excepto el default)
if [ -n "$SGS" ]; then
    echo "Eliminando security groups..."
    for sg_id in $SGS; do
        SG_NAME=$(ibmcloud is security-group $sg_id --output json | jq -r '.name')
        if [[ ! "$SG_NAME" =~ "default" ]]; then
            echo "  Eliminando security group: $sg_id ($SG_NAME)"
            ibmcloud is security-group-delete $sg_id --force &> /dev/null || true
        fi
    done
    sleep 5
fi

# Eliminar VPC
echo "Eliminando VPC..."
if ibmcloud is vpc-delete $VPC_ID --force; then
    echo ""
    echo "✓ VPC 'langflow-vpc' eliminado exitosamente."
    echo ""
    echo "Ahora puedes volver a Schematics y hacer 'Apply plan' con el prefix 'langflow'."
else
    echo ""
    echo "❌ Error al eliminar el VPC."
    echo "Puede que tenga recursos dependientes adicionales (VSIs, Load Balancers, etc.)"
    echo ""
    echo "SOLUCIÓN RECOMENDADA:"
    echo "Cambia el prefix en Schematics a 'langflow-v2' para evitar este conflicto."
fi
