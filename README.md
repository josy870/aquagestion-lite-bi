# AquaGestión Lite — Pipeline BI Completo

Sistema de Inteligencia de Negocios para la gestión operativa de una piscigranja
de truchas arcoíris ubicada en la cuenca del **Lago Titicaca, Puno**.

**Estudiante:** Joselyn Milagros Yucra Mamani  
**Curso:** Inteligencia de Negocios — VIII Ciclo  
**Año:** 2026  
**Repo:** https://github.com/josy870/aquagestion-lite-bi

---

## Problema de Negocio

Los registros de mortalidad y alimentación de truchas se llevan en hojas de cálculo
desordenadas y cuadernos físicos. Esto impide visualizar el histórico de pérdidas,
analizar tendencias y tomar decisiones oportunas sobre la ración de alimento.

---

## Arquitectura del Pipeline

```
PostgreSQL OLTP (local:5432)
        │
        │ postgres_fdw
        ▼
PostgreSQL DW (Docker:15432)
        │  schema: raw (Bronze)
        │
        │ dbt run
        ▼
        │  schema: staging (Silver)
        │
        │ dbt run
        ▼
        │  schema: dm (Gold)
        │
        │ Power BI Desktop
        ▼
Dashboard — 4 KPIs
```

---

## Estructura del Repositorio

```
aquagestion-lite-bi/
├── README.md
├── oltp-pg/                          Parte A — OLTP
│   ├── 01_crear_esquema_oltp.sql
│   └── 02_cargar_datos_oltp.sql
├── datamart/                         Parte A — DataMart manual
│   ├── 03_crear_datamart.sql
│   ├── 04_etl_oltp_a_dm.sql
│   └── 05_validacion_kpis.sql
├── dw-pg/                            Parte B — PostgreSQL DW en Docker
│   ├── docker-compose.yml
│   ├── README.md
│   └── postgres/init/
│       └── 01_create_schemas.sql
├── ingesta-airbyte/                  Parte B — Airbyte (referencia)
│   ├── docker-compose.yml
│   └── README.md
├── dw-dbt/                           Parte C — Modelos dbt
│   ├── Dockerfile
│   ├── docker-compose.yml
│   ├── dbt_project.yml
│   ├── profiles.yml
│   ├── README.md
│   ├── models/
│   │   ├── staging/
│   │   │   ├── sources.yml
│   │   │   ├── stg_poza.sql
│   │   │   ├── stg_lote.sql
│   │   │   └── stg_registro_diario.sql
│   │   └── marts/
│   │       ├── dim_poza.sql
│   │       ├── dim_lote.sql
│   │       ├── dim_tiempo.sql
│   │       ├── dim_condicion.sql
│   │       └── h_registro_diario.sql
│   └── tests/
│       └── test_grain_h_registro_diario.sql
└── powerbi/                          Parte D — Dashboard
    └── aquagestion_bi.pbix
```

---

## KPIs del Proyecto

| # | KPI | Fórmula | Resultado |
|---|-----|---------|-----------|
| 1 | Tasa de Mortalidad | `AVG(tasa_mortalidad) × 100` | 0.02% promedio |
| 2 | Consumo de Alimento | `SUM(kg_alimento)` | 337.50 kg total |
| 3 | Total Bajas | `SUM(cantidad_bajas)` | 34 alevinos |
| 4 | Temperatura Promedio | `AVG(temp_promedio)` | 10.74°C promedio |

---

## Modelo Dimensional (Esquema Estrella)

```
              dm.dim_tiempo
                   │
dm.dim_poza ──── dm.h_registro_diario ──── dm.dim_lote
                   │
             dm.dim_condicion
```

**Tabla de hechos:** `h_registro_diario`  
**Granularidad:** un registro por día × poza × lote  
**Periodo:** Enero – Junio 2025

---

## Orden de Ejecución desde Cero

### Prerrequisitos
- PostgreSQL 17 instalado en Windows
- Docker Desktop corriendo

### Paso 1 — OLTP
```powershell
# En pgAdmin, conectar a localhost:5432
# Crear base de datos: aqua_oltp
# Ejecutar en orden:
# oltp-pg/01_crear_esquema_oltp.sql
# oltp-pg/02_cargar_datos_oltp.sql
```

### Paso 2 — Levantar DW en Docker
```powershell
cd dw-pg
docker compose up -d
```

### Paso 3 — Conectar OLTP → DW (FDW)
```sql
-- Ejecutar en aqua_dw (pgAdmin o VS Code)
CREATE EXTENSION IF NOT EXISTS postgres_fdw;
CREATE SERVER oltp_server
    FOREIGN DATA WRAPPER postgres_fdw
    OPTIONS (host 'host.docker.internal', port '5432', dbname 'aqua_oltp');
CREATE USER MAPPING FOR aqua
    SERVER oltp_server
    OPTIONS (user 'postgres', password 'TU_PASSWORD');
CREATE SCHEMA IF NOT EXISTS oltp;
IMPORT FOREIGN SCHEMA oltp FROM SERVER oltp_server INTO oltp;
```

### Paso 4 — Ejecutar ETL manual
```powershell
# En aqua_dw ejecutar:
# datamart/03_crear_datamart.sql
# datamart/04_etl_oltp_a_dm.sql
# datamart/05_validacion_kpis.sql
```

### Paso 5 — Correr modelos dbt
```powershell
cd dw-dbt
docker compose build   # solo primera vez
docker compose run --rm dbt dbt run
docker compose run --rm dbt dbt test
```

### Paso 6 — Power BI
```
Abrir powerbi/aquagestion_bi.pbix
Origen de datos: localhost:15432 / aqua_dw / usuario: aqua
```

---

## Cuando apagues la laptop

```powershell
# Levantar DW
cd dw-pg
docker compose up -d

# Correr dbt (actualiza el DataMart)
cd ..\dw-dbt
docker compose run --rm dbt dbt run

# Abrir Power BI y actualizar datos
```

---

## Hallazgos del Análisis

- La tasa de mortalidad aumenta cuando la temperatura baja de 12°C (inicio del friaje)
- Poza Norte 1 presenta la mayor mortalidad acumulada — requiere intervención prioritaria
- El consumo de alimento de Poza Central es el más alto por tener el lote de engorde
- La correlación temperatura-mortalidad es inversa y más pronunciada en alevinos
