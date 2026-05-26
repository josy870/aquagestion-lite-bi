# dw-dbt — Modelos dbt para AquaGestión Lite

Proyecto dbt que transforma los datos replicados por Airbyte en el DataMart dimensional.

## Arquitectura

```
raw (Bronze)      → staging (Silver)    → dm (Gold)
─────────────────────────────────────────────────────
raw.poza          → stg_poza            → dim_poza
raw.lote          → stg_lote            → dim_lote
raw.registro      → stg_registro_diario → h_registro_diario
[generado]        →                     → dim_tiempo
[valores fijos]   →                     → dim_condicion
```

## Requisitos

- Docker Desktop corriendo
- Contenedor `aqua-dw-pg` activo (dw-pg)

## Primer uso — construir la imagen

```powershell
cd D:\aquagestion-lite-bi\dw-dbt
docker compose build
```

## Comandos principales

```powershell
# Verificar conexión al DW
docker compose run --rm dbt dbt debug

# Correr todos los modelos
docker compose run --rm dbt dbt run

# Correr solo staging
docker compose run --rm dbt dbt run --select staging

# Correr solo marts
docker compose run --rm dbt dbt run --select marts

# Correr tests
docker compose run --rm dbt dbt test

# Ver linaje de modelos
docker compose run --rm dbt dbt ls
```

## Orden de ejecución de modelos

dbt resuelve las dependencias automáticamente con `ref()`:

```
stg_poza  ──────────────────────────────► dim_poza ─────┐
stg_lote  ──────────────────────────────► dim_lote ─────┤
stg_registro_diario ────────────────────►               ├─► h_registro_diario
                    dim_tiempo (generate_series) ───────┤
                    dim_condicion (valores fijos) ───────┘
```

## Cuando apagues la laptop

```powershell
# Volver a levantar el DW antes de correr dbt
cd D:\aquagestion-lite-bi\dw-pg
docker compose up -d

# Luego correr dbt
cd D:\aquagestion-lite-bi\dw-dbt
docker compose run --rm dbt dbt run
```
