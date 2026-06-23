# Configuración del entorno

Secuencia para dejar el proyecto operativo en una **PC nueva** (Windows).

## 1. Instalar las herramientas base

| Herramienta | Notas |
| --- | --- |
| PostgreSQL 17 | El servidor OLTP local (puerto `5432`). |
| Docker Desktop | Para el DW (PostgreSQL 16) y dbt. |
| VS Code | Con la extensión **Database Client** (Weijan Chen). |
| Git | Para clonar el repositorio. |
| Power BI Desktop | Para abrir el `.pbix`. |

!!! warning "La extensión no es un servidor"
    La extensión *Database Client* de VS Code es **solo un cliente**: no reemplaza la
    instalación del servidor PostgreSQL.

## 2. Clonar el repositorio

```bash
git clone https://github.com/tu-usuario/aquagestion-lite-bi.git
cd aquagestion-lite-bi
```

## 3. Restaurar el OLTP (PostgreSQL 17)

1. Crea la base y el esquema `aquagestion_puno`.
2. Ejecuta el DDL y los datos de la carpeta `oltp-pg/`.

!!! tip "Cargar archivos SQL grandes en VS Code"
    Usa **clic derecho sobre el nombre de la base → “Importar SQL”**. El editor de
    *Query* se abre directo bajo el nombre de la base, no dentro de las subcarpetas de
    esquema. Los scripts DDL+DML pueden mostrar solo mensajes `NOTICE`; verifica el éxito
    con consultas `SELECT COUNT(*)` manuales.

## 4. Levantar el Data Warehouse (Docker)

```bash
# Los docker-compose.yml viven en subcarpetas, no en la raíz.
dir /s docker-compose.yml          REM (Windows) localiza los archivos

cd dw-pg
docker compose up -d
```

!!! danger "Docker Desktop debe estar corriendo"
    El error `unable to get image: failed to connect to docker API at
    npipe:////./pipe/docker_engine` significa, de forma consistente, que **Docker Desktop
    no está iniciado** — no es un problema de configuración.

## 5. Configurar la replicación postgres_fdw

Sigue la [Guía 2 — Ingesta](guias/02-ingesta-fdw.md). Recuerda usar
`host.docker.internal` como host del servidor foráneo.

## 6. Ejecutar dbt

```bash
cd dw-dbt
docker compose run --rm dbt dbt run
docker compose run --rm dbt dbt test
```

!!! note "Comando correcto"
    Es `docker compose run --rm dbt dbt run` (el primer `dbt` es el **servicio** de
    compose; el segundo es el **comando** dbt). No es `dbt dbt run` por sí solo.

## 7. Abrir el dashboard

Abre `powerbi/AquaGestion.pbix` en Power BI Desktop y actualiza la conexión al DW
(`localhost:15432` desde el host de Windows).
