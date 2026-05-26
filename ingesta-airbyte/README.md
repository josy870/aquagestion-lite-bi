# ingesta-airbyte — Réplica OLTP → DW

Airbyte replica las tablas del OLTP (PostgreSQL) hacia el schema `raw`
del Data Warehouse. dbt toma desde ahí.

## Requisito previo

El contenedor `dw-pg` debe estar corriendo antes de levantar Airbyte.

```powershell
# Verificar que aqua-dw-pg está Up
docker ps | findstr aqua-dw-pg
```

---

## Paso 1 — Levantar Airbyte

```powershell
cd aquagestion-lite-bi\ingesta-airbyte
docker compose up -d
```

La primera vez descarga ~1.5 GB de imágenes. Espera 3-5 minutos.

Verificar que todos los contenedores están Up:
```powershell
docker ps
```
Debes ver: `airbyte-db`, `airbyte-server`, `airbyte-webapp`, `airbyte-temporal`, `airbyte-worker`

---

## Paso 2 — Abrir la UI de Airbyte

Abre tu navegador en:
```
http://localhost:8000
```

Credenciales:
- Usuario: `airbyte`
- Password: `password`

---

## Paso 3 — Configurar la fuente (Source)

La fuente es tu PostgreSQL OLTP (el que tiene `oltp.poza`, `oltp.lote`, `oltp.registro_diario`).

1. En el menú izquierdo → **Sources** → **+ New source**
2. Busca y selecciona: **Postgres**
3. Completa los campos:

| Campo | Valor |
|-------|-------|
| Source name | `AquaGestion OLTP` |
| Host | `host.docker.internal` |
| Port | `5432` (o el puerto de tu OLTP) |
| Database | nombre de tu base OLTP |
| Username | tu usuario |
| Password | tu contraseña |
| Default Schema | `oltp` |
| Replication method | `Standard (Xmin)` |

> **Nota Windows:** usa `host.docker.internal` como host para que Airbyte
> pueda acceder al PostgreSQL que corre en tu máquina fuera de Docker.

4. Clic en **Test and save** — debe aparecer ✓ verde.

---

## Paso 4 — Configurar el destino (Destination)

El destino es tu PostgreSQL DW (`aqua-dw-pg`).

1. Menú izquierdo → **Destinations** → **+ New destination**
2. Busca y selecciona: **Postgres**
3. Completa los campos:

| Campo | Valor |
|-------|-------|
| Destination name | `AquaGestion DW` |
| Host | `host.docker.internal` |
| Port | `15432` |
| Database | `aqua_dw` |
| Username | `aqua` |
| Password | `aqua1234` |
| Default Schema | `raw` |

4. Clic en **Test and save** — debe aparecer ✓ verde.

---

## Paso 5 — Crear la conexión (Connection)

1. Menú izquierdo → **Connections** → **+ New connection**
2. Selecciona la fuente: `AquaGestion OLTP`
3. Selecciona el destino: `AquaGestion DW`
4. En la pantalla de configuración:

| Configuración | Valor |
|---------------|-------|
| Connection name | `oltp-to-dw` |
| Replication frequency | `Manual` (para el proyecto académico) |
| Destination namespace | `raw` |
| Streams a sincronizar | Activa: `poza`, `lote`, `registro_diario` |

5. Clic en **Set up connection**

---

## Paso 6 — Ejecutar la sincronización

1. Dentro de la conexión `oltp-to-dw`
2. Clic en **Sync now**
3. Espera que el estado cambie a **Succeeded** (1-2 minutos)

---

## Paso 7 — Verificar en pgAdmin

Conéctate al DW (`localhost:15432`, db: `aqua_dw`) y ejecuta:

```sql
-- Verificar que llegaron datos al schema raw
SELECT
    table_name,
    (xpath('//row', xmlelement(name root,
        query_to_xml('SELECT count(*) FROM raw.' || table_name, false, false, ''))))[1]::text AS filas
FROM information_schema.tables
WHERE table_schema = 'raw'
ORDER BY table_name;
```

O más simple, consulta directamente:
```sql
SELECT COUNT(*) FROM raw.poza;
SELECT COUNT(*) FROM raw.lote;
SELECT COUNT(*) FROM raw.registro_diario;
```

Los datos llegan en columna `_airbyte_data` como JSONB. Para verlos:
```sql
SELECT _airbyte_data FROM raw.poza LIMIT 5;

-- Extraer campos individuales:
SELECT
    _airbyte_data->>'id_poza'     AS id_poza,
    _airbyte_data->>'nombre_poza' AS nombre_poza,
    _airbyte_data->>'sector'      AS sector
FROM raw.poza;
```

---

## Resumen de puertos

| Servicio | Puerto | Para qué |
|----------|--------|----------|
| Airbyte UI | 8000 | Configurar conexiones |
| Airbyte API | 8001 | Uso interno |
| PostgreSQL DW | 15432 | pgAdmin / dbt / Power BI |

---

## Cuando apagues la laptop

Para volver a levantar todo después de apagar:

```powershell
# 1. Primero el DW
cd aquagestion-lite-bi\dw-pg
docker compose up -d

# 2. Luego Airbyte
cd ..\ingesta-airbyte
docker compose up -d
```
