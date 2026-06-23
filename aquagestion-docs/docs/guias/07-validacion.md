# 7. Validación de KPIs

## Objetivo

Demostrar que los KPIs del tablero son **confiables**, conciliando los resultados de SQL
sobre el Data Mart contra las medidas de Power BI.

## 1. Conciliación SQL vs Power BI

| KPI | Resultado SQL | Resultado Power BI | Δ | Estado |
| --- | ---: | ---: | ---: | --- |
| Tasa de Mortalidad | _[%]_ | _[%]_ | 0 | Correcto |
| Consumo de Alimento | _[kg]_ | _[kg]_ | 0 | Correcto |
| Total Bajas | _[n]_ | _[n]_ | 0 | Correcto |
| Temperatura Promedio | _[°C]_ | _[°C]_ | 0 | Correcto |

!!! note
    Reemplaza los valores `[...]` por tus cifras reales. La diferencia (Δ) debe ser 0.

## 2. Consultas de validación

```sql
-- Consumo de alimento total (2025)
SELECT SUM(h.alimento_kg) AS consumo_2025
FROM dm.h_registro_diario h
JOIN dm.dim_tiempo t ON h.sk_fecha = t.sk_fecha
WHERE t.anio = 2025;

-- Total de bajas por sector
SELECT po.sector, SUM(h.bajas) AS total_bajas
FROM dm.h_registro_diario h
JOIN dm.dim_poza po ON h.sk_poza = po.sk_poza
GROUP BY po.sector
ORDER BY total_bajas DESC;
```

## 3. Calidad de datos (dbt tests)

| Control | Regla | Prueba dbt |
| --- | --- | --- |
| Completitud | Sin nulos en claves y métricas | `not_null` |
| Unicidad | Sin duplicados de grano | `unique` |
| Integridad referencial | FKs válidas hacia dimensiones | `relationships` |
| Rango válido | Fechas dentro de 2024–2025 | `accepted_values` / rango |

Resultado esperado: **PASS=8, WARN=0, ERROR=0**.

## 4. Trazabilidad

Cada KPI se rastrea de punta a punta:

```text
OLTP → raw → staging → DataMart → medida DAX → visual
```

!!! success "Evidencia para el informe"
    Captura la tabla de conciliación con tus cifras reales, la salida de `dbt test` y la
    matriz de trazabilidad.
