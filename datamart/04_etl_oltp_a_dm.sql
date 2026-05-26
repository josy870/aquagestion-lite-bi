-- ============================================================
--  AquaGestión Lite — SCRIPT 04
--  ETL: Poblar DataMart desde OLTP
--  Motor: PostgreSQL
--  Ejecutar después de: 03_crear_datamart.sql
-- ============================================================
--
--  ORDEN DE CARGA (respeta dependencias FK):
--  1. dim_condicion  → valores fijos, no viene del OLTP
--  2. dim_poza       → desde oltp.poza
--  3. dim_lote       → desde oltp.lote
--  4. dim_tiempo     → generado con generate_series()
--  5. h_registro_diario → desde oltp.registro_diario + joins con dims
-- ============================================================


-- ============================================================
--  PASO 1: POBLAR dim_condicion
--  Valores fijos basados en rangos reales del Lago Titicaca.
--  No vienen del OLTP — se cargan una sola vez.
-- ============================================================

TRUNCATE TABLE dm.dim_condicion RESTART IDENTITY CASCADE;

INSERT INTO dm.dim_condicion
    (rango_temperatura, temp_min, temp_max, estado, color_semaforo, descripcion)
VALUES
    ('< 10°C',   -99.00,  9.99, 'Crítico',  '#C00000', 'Temperatura muy baja. Alta mortalidad. Peces en estrés severo.'),
    ('10–12°C',   10.00, 11.99, 'Bajo',     '#FF9900', 'Por debajo del rango óptimo. Crecimiento lento, mayor susceptibilidad.'),
    ('12–14°C',   12.00, 13.99, 'Óptimo',   '#00B050', 'Rango óptimo para trucha arcoíris en el Titicaca. Mejor FCR.'),
    ('14–16°C',   14.00, 15.99, 'Alto',     '#FFFF00', 'Límite superior tolerable. Monitorear oxígeno disuelto.'),
    ('> 16°C',    16.00, 99.99, 'Muy Alto', '#C00000', 'Temperatura crítica alta. Riesgo de floraciones algales.');

SELECT 'dim_condicion' AS tabla, COUNT(*) AS filas FROM dm.dim_condicion;
-- Resultado esperado: 5


-- ============================================================
--  PASO 2: POBLAR dim_poza
--  Desde: oltp.poza
-- ============================================================

TRUNCATE TABLE dm.dim_poza RESTART IDENTITY CASCADE;

INSERT INTO dm.dim_poza (id_poza, nombre_poza, sector, granja, capacidad_m3, estado)
SELECT
    p.id_poza,
    p.nombre_poza,
    p.sector,
    'AquaGestión Puno'  AS granja,
    p.capacidad_m3,
    p.estado
FROM oltp.poza p
ORDER BY p.id_poza;

SELECT 'dim_poza' AS tabla, COUNT(*) AS filas FROM dm.dim_poza;
-- Resultado esperado: 5


-- ============================================================
--  PASO 3: POBLAR dim_lote
--  Desde: oltp.lote
-- ============================================================

TRUNCATE TABLE dm.dim_lote RESTART IDENTITY CASCADE;

INSERT INTO dm.dim_lote
    (id_lote, nombre_lote, especie, etapa, fecha_ingreso, poblacion_inicial, proveedor)
SELECT
    l.id_lote,
    l.nombre_lote,
    l.especie,
    l.etapa,
    l.fecha_ingreso,
    l.poblacion_inicial,
    l.proveedor
FROM oltp.lote l
ORDER BY l.id_lote;

SELECT 'dim_lote' AS tabla, COUNT(*) AS filas FROM dm.dim_lote;
-- Resultado esperado: 6


-- ============================================================
--  PASO 4: POBLAR dim_tiempo
--  Generado automáticamente con generate_series()
--  Cubre el periodo completo del proyecto: Ene–Jun 2025
-- ============================================================

TRUNCATE TABLE dm.dim_tiempo CASCADE;

INSERT INTO dm.dim_tiempo (
    sk_fecha, fecha, dia, nombre_dia, es_fin_semana,
    semana_iso, mes, nombre_mes, trimestre, nombre_trimestre,
    semestre, anio, es_feriado, nombre_feriado
)
SELECT
    TO_CHAR(d, 'YYYYMMDD')                                          AS sk_fecha,
    d::DATE                                                          AS fecha,
    EXTRACT(DAY     FROM d)::SMALLINT                               AS dia,
    TO_CHAR(d, 'TMDay')                                             AS nombre_dia,
    EXTRACT(DOW     FROM d) IN (0, 6)                               AS es_fin_semana,
    EXTRACT(WEEK    FROM d)::SMALLINT                               AS semana_iso,
    EXTRACT(MONTH   FROM d)::SMALLINT                               AS mes,
    TO_CHAR(d, 'TMMonth')                                           AS nombre_mes,
    EXTRACT(QUARTER FROM d)::SMALLINT                               AS trimestre,
    'Q' || EXTRACT(QUARTER FROM d)::TEXT                            AS nombre_trimestre,
    CASE WHEN EXTRACT(MONTH FROM d) <= 6 THEN 1 ELSE 2 END::SMALLINT AS semestre,
    EXTRACT(YEAR    FROM d)::SMALLINT                               AS anio,
    -- Feriados nacionales peruanos en el periodo Ene–Jun 2025
    d::DATE IN (
        '2025-01-01',  -- Año Nuevo
        '2025-04-17',  -- Jueves Santo
        '2025-04-18',  -- Viernes Santo
        '2025-05-01',  -- Día del Trabajo
        '2025-06-07'   -- Batalla de Arica
    )                                                               AS es_feriado,
    CASE d::DATE
        WHEN '2025-01-01' THEN 'Año Nuevo'
        WHEN '2025-04-17' THEN 'Jueves Santo'
        WHEN '2025-04-18' THEN 'Viernes Santo'
        WHEN '2025-05-01' THEN 'Día del Trabajo'
        WHEN '2025-06-07' THEN 'Batalla de Arica'
        ELSE NULL
    END                                                             AS nombre_feriado
FROM generate_series(
    '2025-01-01'::DATE,
    '2025-06-30'::DATE,
    '1 day'
) AS d;

SELECT 'dim_tiempo' AS tabla, COUNT(*) AS filas FROM dm.dim_tiempo;
-- Resultado esperado: 181 días


-- ============================================================
--  PASO 5: POBLAR h_registro_diario
--
--  Join: oltp.registro_diario
--        + dim_poza   (por id_poza)
--        + dim_lote   (por id_lote  → trae poblacion_inicial)
--        + dim_tiempo (por fecha    → trae sk_fecha)
--        + dim_condicion (por rango de temperatura)
--
--  Métrica calculada: tasa_mortalidad = bajas / poblacion_inicial
-- ============================================================

TRUNCATE TABLE dm.h_registro_diario RESTART IDENTITY;

INSERT INTO dm.h_registro_diario (
    sk_fecha,
    sk_poza,
    sk_lote,
    sk_condicion,
    kg_alimento,
    cantidad_bajas,
    temp_promedio,
    tasa_mortalidad
)
SELECT
    t.sk_fecha,
    p.sk_poza,
    l.sk_lote,
    c.sk_condicion,
    r.kg_alimento,
    r.cantidad_bajas,
    r.temp_promedio,
    -- Tasa de mortalidad calculada (métrica derivada)
    ROUND(
        r.cantidad_bajas::NUMERIC / NULLIF(l.poblacion_inicial, 0),
        6
    )                                                   AS tasa_mortalidad
FROM oltp.registro_diario r
-- Join con dim_tiempo (por fecha)
JOIN dm.dim_tiempo  t ON t.fecha    = r.fecha
-- Join con dim_poza (por natural key)
JOIN dm.dim_poza    p ON p.id_poza  = r.id_poza
-- Join con dim_lote (por natural key, trae poblacion_inicial)
JOIN dm.dim_lote    l ON l.id_lote  = r.id_lote
-- Join con dim_condicion (por rango de temperatura)
JOIN dm.dim_condicion c ON (
    r.temp_promedio IS NOT NULL
    AND r.temp_promedio >= c.temp_min
    AND r.temp_promedio <  c.temp_max
)
ORDER BY r.fecha, r.id_poza, r.id_lote;

SELECT 'h_registro_diario' AS tabla, COUNT(*) AS filas FROM dm.h_registro_diario;


-- ============================================================
--  PASO 6: VERIFICACIÓN GENERAL
-- ============================================================

SELECT 'dim_condicion'    AS tabla, COUNT(*) AS filas FROM dm.dim_condicion
UNION ALL
SELECT 'dim_poza',                  COUNT(*) FROM dm.dim_poza
UNION ALL
SELECT 'dim_lote',                  COUNT(*) FROM dm.dim_lote
UNION ALL
SELECT 'dim_tiempo',                COUNT(*) FROM dm.dim_tiempo
UNION ALL
SELECT 'h_registro_diario',         COUNT(*) FROM dm.h_registro_diario;

-- Verificar grano: no debe haber duplicados (día × poza × lote)
SELECT sk_fecha, sk_poza, sk_lote, COUNT(*) AS repeticiones
FROM dm.h_registro_diario
GROUP BY sk_fecha, sk_poza, sk_lote
HAVING COUNT(*) > 1;
-- Resultado esperado: 0 filas (sin duplicados)

-- Verificar FK de dim_condicion: registros sin condición asignada
-- (ocurre si temp_promedio es NULL o fuera de rangos)
SELECT COUNT(*) AS registros_sin_condicion
FROM oltp.registro_diario r
WHERE r.temp_promedio IS NULL
   OR NOT EXISTS (
       SELECT 1 FROM dm.dim_condicion c
       WHERE r.temp_promedio >= c.temp_min
         AND r.temp_promedio <  c.temp_max
   );
