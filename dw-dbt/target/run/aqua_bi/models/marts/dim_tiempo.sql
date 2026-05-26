
  
    

  create  table "aqua_dw"."dm_dm"."dim_tiempo__dbt_tmp"
  
  
    as
  
  (
    -- ============================================================
--  dm.dim_tiempo
--  Dimensión calendario — generada por dbt con generate_series
--  Cubre: Ene–Jun 2025
-- ============================================================

WITH fechas AS (

    SELECT
        generate_series(
            '2025-01-01'::DATE,
            '2025-06-30'::DATE,
            '1 day'::INTERVAL
        )::DATE AS fecha

),

calendario AS (

    SELECT
        TO_CHAR(fecha, 'YYYYMMDD')                                          AS sk_fecha,
        fecha,
        EXTRACT(DAY     FROM fecha)::SMALLINT                               AS dia,
        TO_CHAR(fecha, 'TMDay')                                             AS nombre_dia,
        EXTRACT(DOW     FROM fecha) IN (0, 6)                               AS es_fin_semana,
        EXTRACT(WEEK    FROM fecha)::SMALLINT                               AS semana_iso,
        EXTRACT(MONTH   FROM fecha)::SMALLINT                               AS mes,
        TO_CHAR(fecha, 'TMMonth')                                           AS nombre_mes,
        EXTRACT(QUARTER FROM fecha)::SMALLINT                               AS trimestre,
        'Q' || EXTRACT(QUARTER FROM fecha)::TEXT                            AS nombre_trimestre,
        CASE WHEN EXTRACT(MONTH FROM fecha) <= 6 THEN 1 ELSE 2
        END::SMALLINT                                                       AS semestre,
        EXTRACT(YEAR    FROM fecha)::SMALLINT                               AS anio,
        -- Feriados nacionales peruanos Ene–Jun 2025
        fecha IN (
            '2025-01-01',
            '2025-04-17',
            '2025-04-18',
            '2025-05-01',
            '2025-06-07'
        )                                                                   AS es_feriado,
        CASE fecha
            WHEN '2025-01-01' THEN 'Año Nuevo'
            WHEN '2025-04-17' THEN 'Jueves Santo'
            WHEN '2025-04-18' THEN 'Viernes Santo'
            WHEN '2025-05-01' THEN 'Día del Trabajo'
            WHEN '2025-06-07' THEN 'Batalla de Arica'
            ELSE NULL
        END                                                                 AS nombre_feriado
    FROM fechas

)

SELECT * FROM calendario
  );
  