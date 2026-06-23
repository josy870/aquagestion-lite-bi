# 2. Ingesta — postgres_fdw

## Objetivo

Replicar las tablas del OLTP (host de Windows) dentro del Data Warehouse dockerizado,
usando el *Foreign Data Wrapper* de PostgreSQL. Esta es la **capa raw (Bronze)**.

## Por qué postgres_fdw

Se intentó Airbyte, pero las versiones 0.50.11 y 0.50.33 fueron incompatibles con Docker
Desktop sobre Windows. `postgres_fdw` resuelve la misma necesidad —exponer los datos del
OLTP dentro del DW— de forma estable y reproducible.

## Pasos

Ejecuta lo siguiente **dentro del DW** (PostgreSQL 16, puerto `15432`).

### 1. Habilitar la extensión

```sql
CREATE EXTENSION IF NOT EXISTS postgres_fdw;
```

### 2. Crear el servidor foráneo

!!! danger "Usa host.docker.internal, no localhost"
    El DW corre en un contenedor; `localhost` apuntaría al propio contenedor. Para
    alcanzar el OLTP del host de Windows usa `host.docker.internal` (o la IP de la LAN).

```sql
CREATE SERVER oltp_aquagestion
  FOREIGN DATA WRAPPER postgres_fdw
  OPTIONS (host 'host.docker.internal', port '5432', dbname 'aquagestion');
```

### 3. Mapear el usuario

```sql
CREATE USER MAPPING FOR CURRENT_USER
  SERVER oltp_aquagestion
  OPTIONS (user 'postgres', password '********');  -- (1)
```

1. Reemplaza por las credenciales reales de tu OLTP. **No subas la contraseña al repo.**

### 4. Importar el esquema como capa raw

```sql
CREATE SCHEMA IF NOT EXISTS raw;

IMPORT FOREIGN SCHEMA aquagestion_puno
  FROM SERVER oltp_aquagestion
  INTO raw;
```

## Verificación

```sql
-- Las tablas foráneas deben responder con los mismos volúmenes que el OLTP
SELECT COUNT(*) FROM raw.registro_diario;
```

!!! success "Evidencia para el informe"
    Captura la creación del servidor foráneo y un `COUNT(*)` desde `raw` que coincida con
    el volumen del OLTP.
