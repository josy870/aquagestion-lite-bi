-- ============================================================
--  AquaGestión Lite — SCRIPT 05
--  Validación Analítica — 4 KPIs del Proyecto
--  Motor: PostgreSQL | Esquema: dm
--  Ejecutar después de: 04_etl_oltp_a_dm.sql
-- ============================================================
--
--  KPI 1 → Tasa de Mortalidad (%) por poza y mes
--  KPI 2 → Consumo de Alimento (kg) por poza y mes
--  KPI 3 → Total de Bajas por poza (ranking de pozas críticas)
--  KPI 4 → Temperatura Promedio del Agua por mes
--  BONUS → Correlación temperatura vs mortalidad
-- ============================================================


-- ============================================================
--  VALIDACIÓN ESTRUCTURAL
-- ============================================================

-- Conteo de filas por tabla (debe coincidir con paso 6 del ETL)
SELECT 'dim_condicion'    AS tabla, COUNT(*) AS filas FROM dm.dim_condicion
UNION ALL
SELECT 'dim_poza',                  COUNT(*) FROM dm.dim_poza
UNION ALL
SELECT 'dim_lote',                  COUNT(*) FROM dm.dim_lote
UNION ALL
SELECT 'dim_tiempo',                COUNT(*) FROM dm.dim_tiempo
UNION ALL
SELECT 'h_registro_diario',         COUNT(*) FROM dm.h_registro_diario;

-- Validar grano (cero duplicados es el resultado correcto)
SELECT sk_fecha, sk_poza, sk_lote, COUNT(*) AS repeticiones
FROM dm.h_registro_diario
GROUP BY sk_fecha, sk_poza, sk_lote
HAVING COUNT(*) > 1;

-- Cruce OLTP vs DataMart: total de registros debe ser igual
SELECT
    (SELECT COUNT(*) FROM oltp.registro_diario)   AS registros_oltp,
    (SELECT COUNT(*) FROM dm.h_registro_diario)   AS registros_dm;


-- ============================================================
--  KPI 1 — TASA DE MORTALIDAD (%)
--  Fórmula: (Cantidad_Bajas / Población_Inicial) × 100
--  Semáforo: < 2% Baja | 2–5% Aceptable | > 5% Crítica
-- ============================================================

-- 1a. Tasa de mortalidad mensual por poza
SELECT
    p.nombre_poza,
    p.sector,
    t.nombre_mes,
    t.anio,
    SUM(h.cantidad_bajas)                               AS total_bajas_mes,
    ROUND(AVG(h.tasa_mortalidad) * 100, 4)             AS tasa_mortalidad_pct,
    CASE
        WHEN AVG(h.tasa_mortalidad) * 100 < 2    THEN 'Baja ✓'
        WHEN AVG(h.tasa_mortalidad) * 100 <= 5   THEN 'Aceptable ⚠'
        ELSE                                          'Crítica ✗'
    END                                                 AS semaforo
FROM dm.h_registro_diario h
JOIN dm.dim_poza   p ON h.sk_poza  = p.sk_poza
JOIN dm.dim_tiempo t ON h.sk_fecha = t.sk_fecha
GROUP BY p.nombre_poza, p.sector, t.anio, t.mes, t.nombre_mes
ORDER BY t.anio, t.mes, tasa_mortalidad_pct DESC;


-- 1b. Tasa de mortalidad acumulada por lote (total del periodo)
SELECT
    l.id_lote,
    l.nombre_lote,
    l.etapa,
    l.poblacion_inicial,
    SUM(h.cantidad_bajas)                               AS total_bajas_acumuladas,
    ROUND(SUM(h.cantidad_bajas)::NUMERIC
          / NULLIF(l.poblacion_inicial, 0) * 100, 2)   AS mortalidad_acumulada_pct
FROM dm.h_registro_diario h
JOIN dm.dim_lote l ON h.sk_lote = l.sk_lote
GROUP BY l.sk_lote, l.id_lote, l.nombre_lote, l.etapa, l.poblacion_inicial
ORDER BY mortalidad_acumulada_pct DESC;


-- ============================================================
--  KPI 2 — CONSUMO DE ALIMENTO (kg)
--  Fórmula: SUM(Kg_Alimento) por poza y periodo
-- ============================================================

-- 2a. Consumo mensual por poza
SELECT
    p.nombre_poza,
    t.nombre_mes,
    t.anio,
    ROUND(SUM(h.kg_alimento), 3)    AS kg_alimento_mes,
    COUNT(*)                         AS dias_registrados,
    ROUND(AVG(h.kg_alimento), 3)    AS kg_alimento_dia_promedio
FROM dm.h_registro_diario h
JOIN dm.dim_poza   p ON h.sk_poza  = p.sk_poza
JOIN dm.dim_tiempo t ON h.sk_fecha = t.sk_fecha
GROUP BY p.nombre_poza, t.anio, t.mes, t.nombre_mes
ORDER BY t.anio, t.mes, kg_alimento_mes DESC;


-- 2b. Consumo total acumulado por poza (periodo completo)
SELECT
    p.nombre_poza,
    p.sector,
    ROUND(SUM(h.kg_alimento), 3)    AS kg_alimento_total,
    SUM(h.cantidad_bajas)            AS total_bajas
FROM dm.h_registro_diario h
JOIN dm.dim_poza p ON h.sk_poza = p.sk_poza
GROUP BY p.nombre_poza, p.sector
ORDER BY kg_alimento_total DESC;


-- ============================================================
--  KPI 3 — TOTAL BAJAS POR POZA
--  Identifica las pozas con mayor mortalidad acumulada
-- ============================================================

-- 3a. Ranking de pozas por mortalidad acumulada
SELECT
    ROW_NUMBER() OVER (ORDER BY SUM(h.cantidad_bajas) DESC) AS ranking,
    p.nombre_poza,
    p.sector,
    SUM(h.cantidad_bajas)                               AS total_bajas,
    ROUND(AVG(h.tasa_mortalidad) * 100, 4)             AS tasa_promedio_pct,
    CASE
        WHEN AVG(h.tasa_mortalidad) * 100 < 2    THEN 'Normal'
        WHEN AVG(h.tasa_mortalidad) * 100 <= 5   THEN 'Atención'
        ELSE                                          'Crítica'
    END                                                 AS nivel_riesgo
FROM dm.h_registro_diario h
JOIN dm.dim_poza p ON h.sk_poza = p.sk_poza
GROUP BY p.sk_poza, p.nombre_poza, p.sector
ORDER BY total_bajas DESC;


-- 3b. Evolución de bajas acumuladas por lote (para gráfico de área)
SELECT
    t.fecha,
    l.nombre_lote,
    l.etapa,
    h.cantidad_bajas                                    AS bajas_dia,
    SUM(h.cantidad_bajas) OVER (
        PARTITION BY h.sk_lote
        ORDER BY t.fecha
    )                                                   AS bajas_acumuladas
FROM dm.h_registro_diario h
JOIN dm.dim_tiempo t ON h.sk_fecha = t.sk_fecha
JOIN dm.dim_lote   l ON h.sk_lote  = l.sk_lote
ORDER BY l.nombre_lote, t.fecha;


-- ============================================================
--  KPI 4 — TEMPERATURA PROMEDIO DEL AGUA (°C)
--  Métrica semi-aditiva: promediar, NUNCA sumar entre pozas
-- ============================================================

-- 4a. Temperatura promedio mensual (global de la granja)
SELECT
    t.anio,
    t.nombre_mes,
    t.mes,
    ROUND(AVG(h.temp_promedio), 2)  AS temp_promedio_mes,
    MIN(h.temp_promedio)             AS temp_minima,
    MAX(h.temp_promedio)             AS temp_maxima
FROM dm.h_registro_diario h
JOIN dm.dim_tiempo t ON h.sk_fecha = t.sk_fecha
WHERE h.temp_promedio IS NOT NULL
GROUP BY t.anio, t.mes, t.nombre_mes
ORDER BY t.anio, t.mes;


-- 4b. Temperatura promedio por poza y mes
SELECT
    p.nombre_poza,
    t.nombre_mes,
    ROUND(AVG(h.temp_promedio), 2)  AS temp_promedio,
    MIN(h.temp_promedio)             AS temp_min,
    MAX(h.temp_promedio)             AS temp_max
FROM dm.h_registro_diario h
JOIN dm.dim_poza   p ON h.sk_poza  = p.sk_poza
JOIN dm.dim_tiempo t ON h.sk_fecha = t.sk_fecha
WHERE h.temp_promedio IS NOT NULL
GROUP BY p.nombre_poza, t.anio, t.mes, t.nombre_mes
ORDER BY t.mes, p.nombre_poza;


-- ============================================================
--  BONUS — CORRELACIÓN TEMPERATURA vs MORTALIDAD
--  Responde: ¿el friaje (temp baja) causa mayor mortalidad?
-- ============================================================

-- Por condición ambiental (agrupa registros por rango de temperatura)
SELECT
    c.rango_temperatura,
    c.estado,
    c.color_semaforo,
    COUNT(*)                                            AS dias_registrados,
    ROUND(AVG(h.temp_promedio), 2)                     AS temp_promedio_real,
    ROUND(AVG(h.tasa_mortalidad) * 100, 4)             AS tasa_mortalidad_promedio_pct,
    ROUND(AVG(h.kg_alimento), 3)                       AS alimento_promedio_kg
FROM dm.h_registro_diario h
JOIN dm.dim_condicion c ON h.sk_condicion = c.sk_condicion
GROUP BY c.sk_condicion, c.rango_temperatura, c.estado, c.color_semaforo, c.temp_min
ORDER BY c.temp_min;

-- Mapa de calor: tasa de mortalidad por Poza × Semana
-- (útil para identificar patrones en el dashboard de Power BI)
SELECT
    p.nombre_poza,
    t.semana_iso,
    t.nombre_mes,
    ROUND(AVG(h.tasa_mortalidad) * 100, 4)             AS tasa_mortalidad_pct,
    SUM(h.cantidad_bajas)                               AS total_bajas_semana
FROM dm.h_registro_diario h
JOIN dm.dim_poza   p ON h.sk_poza  = p.sk_poza
JOIN dm.dim_tiempo t ON h.sk_fecha = t.sk_fecha
GROUP BY p.nombre_poza, t.semana_iso, t.nombre_mes, t.mes
ORDER BY t.mes, t.semana_iso, p.nombre_poza;
