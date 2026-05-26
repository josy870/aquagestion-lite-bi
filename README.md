# AquaGestión Lite — BI para Piscigranja de Truchas

Sistema de Inteligencia de Negocios para la gestión operativa de una piscigranja
de truchas arcoíris ubicada en la cuenca del **Lago Titicaca, Puno**.

**Estudiante:** Joselyn Milagros Yucra Mamani  
**Curso:** Inteligencia de Negocios — VIII Ciclo  
**Año:** 2026

---

## Problema de Negocio

Los registros de mortalidad y alimentación de truchas se llevan en hojas de cálculo
desordenadas y cuadernos físicos. Esto impide visualizar el histórico de pérdidas,
analizar tendencias y tomar decisiones oportunas sobre la ración de alimento.

---

## Arquitectura del Proyecto

```
PostgreSQL OLTP  →  ETL manual SQL  →  PostgreSQL DataMart  →  Power BI
(esquema: oltp)                        (esquema: dm)
```

---

## Estructura del Repositorio

```
aquagestion-lite-bi/
├── README.md
├── oltp-pg/
│   ├── 01_crear_esquema_oltp.sql   → Tablas transaccionales (fuente de datos)
│   └── 02_cargar_datos_oltp.sql    → Datos de ejemplo: pozas, lotes, registros diarios
└── datamart/
    ├── 03_crear_datamart.sql       → Esquema dm: dimensiones + tabla de hechos
    ├── 04_etl_oltp_a_dm.sql        → ETL: poblar DataMart desde OLTP
    └── 05_validacion_kpis.sql      → Consultas analíticas de validación (4 KPIs)
```

---

## KPIs del Proyecto

| # | KPI | Fórmula | Frecuencia |
|---|-----|---------|------------|
| 1 | Tasa de Mortalidad | `(Cantidad_Bajas / Población_Inicial) × 100` | Diario / Mensual |
| 2 | Consumo de Alimento (kg) | `SUM(Kg_Alimento)` por poza y periodo | Diario / Mensual |
| 3 | Total Bajas por Poza | `SUM(Cantidad_Bajas)` | Acumulado |
| 4 | Temperatura Promedio del Agua | `AVG(Temp_Promedio)` | Diario |

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

---

## Orden de Ejecución

Ejecutar los scripts en pgAdmin o DBeaver en este orden:

```
1. oltp-pg/01_crear_esquema_oltp.sql
2. oltp-pg/02_cargar_datos_oltp.sql
3. datamart/03_crear_datamart.sql
4. datamart/04_etl_oltp_a_dm.sql
5. datamart/05_validacion_kpis.sql
```

---

## Fuentes de Datos

| Archivo Excel (OLTP origen) | Tabla PostgreSQL equivalente |
|-----------------------------|------------------------------|
| Pozas.xlsx                  | oltp.poza                    |
| Lote_Peces.xlsx             | oltp.lote                    |
| Registro_Diario.xlsx        | oltp.registro_diario         |
