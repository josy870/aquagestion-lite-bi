# AquaGestión Lite BI

Solución de **Business Intelligence end-to-end** para el monitoreo productivo de una
piscigranja de truchas en la cuenca del **Lago Titicaca** (Puno, Perú).

Este sitio reúne las **guías para construir cada componente** del proyecto, desde la base
transaccional hasta el tablero de decisión en Power BI.

!!! abstract "Producto del Curso — Unidad 3 (Business Intelligence)"
    Pipeline completo: **PostgreSQL 17 (OLTP)** → **postgres_fdw** → **PostgreSQL 16 (DW, Docker)**
    → **dbt Core 1.7.18** → **Power BI Desktop**.

## El problema de negocio

Producir trucha en el Titicaca es una carrera contra el frío. Los eventos de **friaje**
(olas de frío) bajan la temperatura del agua y disparan la mortalidad, mientras el registro
diario se anota de forma dispersa y sin un tablero que permita reaccionar a tiempo.
AquaGestión Lite BI convierte ese registro diario en **decisiones oportunas**.

## Indicadores principales

<div class="grid cards" markdown>

- :material-heart-pulse: __Tasa de Mortalidad__

    Proporción de bajas respecto a la población del lote.

- :material-skull: __Total de Bajas__

    Número de peces muertos en el periodo.

- :material-food-drumstick: __Consumo de Alimento__

    Kilogramos de balanceado suministrados.

- :material-thermometer: __Temperatura Promedio__

    Temperatura media del agua de las pozas.

</div>

## Cómo está organizado este sitio

| Sección | Contenido |
| --- | --- |
| [Arquitectura](arquitectura.md) | Diagrama y flujo de datos de extremo a extremo. |
| [Configuración del entorno](setup-entorno.md) | Cómo dejar el proyecto operativo en una PC nueva. |
| [Guías de construcción](guias/index.md) | Paso a paso para construir cada componente del entregable. |

## Estructura del repositorio

```text
aquagestion-lite-bi/
├── oltp-pg/          # DDL y datos del OLTP (PostgreSQL 17)
├── ingesta-airbyte/  # Intento de ingesta (reemplazado por postgres_fdw)
├── dw-pg/            # Data Warehouse en Docker (PostgreSQL 16)
├── datamart/         # Scripts del esquema dimensional (dm)
├── dw-dbt/           # Proyecto dbt (staging + marts)
├── powerbi/          # Archivo .pbix del dashboard
└── docs/             # Este sitio MkDocs
```

!!! tip "Antes de entregar"
    Reemplaza `[tu nombre]` y la URL del repositorio en `mkdocs.yml`, y agrega tus
    **capturas** en cada guía donde se indique *Evidencia para el informe*.
