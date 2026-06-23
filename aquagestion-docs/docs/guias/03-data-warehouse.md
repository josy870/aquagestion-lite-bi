# 3. Data Warehouse — PostgreSQL 16 (Docker)

## Objetivo

Levantar el almacén analítico en un contenedor Docker (PostgreSQL 16, puerto `15432`), que
alojará la capa `raw` (vía fdw) y el esquema `dm` (Data Mart).

## Pasos

### 1. Localizar el docker-compose

Los archivos `docker-compose.yml` viven en subcarpetas (`dw-pg`, `dw-dbt`), no en la raíz.

```bash
dir /s docker-compose.yml
```

### 2. Levantar el contenedor

```bash
cd dw-pg
docker compose up -d
docker compose ps
```

!!! danger "Si falla la conexión a Docker"
    `failed to connect to docker API at npipe:////./pipe/docker_engine` significa que
    **Docker Desktop no está corriendo**. Inícialo y reintenta.

### 3. Conectar desde VS Code

Crea una conexión en *Database Client* a `localhost:15432` (desde el host de Windows el
puerto del contenedor se ve como `localhost`).

## Ejemplo de docker-compose

```yaml
services:
  dw:
    image: postgres:16
    container_name: aquagestion-dw
    environment:
      POSTGRES_DB: aquagestion_dw
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres   # cámbiala y no la subas al repo
    ports:
      - "15432:5432"
    volumes:
      - dw_data:/var/lib/postgresql/data

volumes:
  dw_data:
```

## Verificación

```sql
SELECT version();           -- debe reportar PostgreSQL 16
SELECT current_database();  -- aquagestion_dw
```

!!! success "Evidencia para el informe"
    Captura `docker compose ps` con el contenedor en estado *Up* y la conexión activa
    desde VS Code.
