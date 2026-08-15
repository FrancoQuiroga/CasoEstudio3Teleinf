#!/bin/sh

echo "=== Iniciando automatización de filtros en Metabase ==="

# 1. Configuración de variables
# Usamos el Service interno de Kubernetes
METABASE_URL="http://metabase-service:3000" 
USERNAME="admin@proyecto.com"
PASSWORD="PasswordSeguro123!"

echo "1. Autenticando en la API de Metabase..."
SESSION_TOKEN=$(curl -s -X POST "${METABASE_URL}/api/session" \
  -H "Content-Type: application/json" \
  -d '{"username": "'"${USERNAME}"'", "password": "'"${PASSWORD}"'"}' | jq -r '.id')

if [ "$SESSION_TOKEN" = "null" ] || [ -z "$SESSION_TOKEN" ]; then
  echo "Error: Falló la autenticación. Revisa que Metabase esté inicializado y las credenciales sean correctas."
  exit 1
fi
echo "-> Token de sesión obtenido exitosamente."

echo "2. Obteniendo el ID de la base de datos 'Google Mobility'..."
DB_ID=$(curl -s -X GET "${METABASE_URL}/api/database" \
  -H "X-Metabase-Session: ${SESSION_TOKEN}" | jq -r '.data[] | select(.name=="Google Mobility") | .id')

if [ -z "$DB_ID" ] || [ "$DB_ID" = "null" ]; then
  echo "No se encontró la base por nombre, usando ID 2 por defecto."
  DB_ID=2
fi
echo "-> Database ID asignado: $DB_ID"

echo "3. Creando la pregunta SQL con filtros de región y fecha..."
# NOTA: Revisa que el nombre de la tabla en el FROM coincida con la que creaste en tu DB
curl -s -X POST "${METABASE_URL}/api/card" \
  -H "Content-Type: application/json" \
  -H "X-Metabase-Session: ${SESSION_TOKEN}" \
  -d '{
    "name": "Análisis de Movilidad - Vista Automática",
    "description": "Pregunta generada por script con filtros para Mendoza.",
    "display": "line",
    "dataset_query": {
      "type": "native",
      "native": {
        "query": "SELECT date, grocery_and_pharmacy_percent_change_from_baseline, parks_percent_change_from_baseline, workplaces_percent_change_from_baseline, retail_and_recreation_percent_change_from_baseline FROM mobility WHERE sub_region_1 = {{sub_region_1}} AND sub_region_2 = {{sub_region_2}} AND date >= {{fecha_desde}} AND date <= {{fecha_hasta}}",
        "template-tags": {
          "sub_region_1": {
            "name": "sub_region_1",
            "display-name": "Sub region 1",
            "type": "text",
            "default": "Mendoza Province"
          },
          "sub_region_2": {
            "name": "sub_region_2",
            "display-name": "Sub region 2",
            "type": "text",
            "default": "Capital Department"
          },
          "fecha_desde": {
            "name": "fecha_desde",
            "display-name": "Fecha desde",
            "type": "date",
            "default": "2020-01-01"
          },
          "fecha_hasta": {
            "name": "fecha_hasta",
            "display-name": "Fecha hasta",
            "type": "date",
            "default": "2020-12-31"
          }
        }
      },
      "database": '"${DB_ID}"'
    },
    "visualization_settings": {
      "graph.dimensions": ["date"],
      "graph.metrics": [
        "grocery_and_pharmacy_percent_change_from_baseline",
        "parks_percent_change_from_baseline",
        "workplaces_percent_change_from_baseline",
        "retail_and_recreation_percent_change_from_baseline"
      ]
    }
  }'

echo -e "\n=== ¡Filtros y gráfico creados exitosamente! ==="