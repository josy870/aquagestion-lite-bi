-- ============================================================
--  dm.h_registro_diario
--  Tabla de hechos principal
--  Granularidad: día × poza × lote
--  Fuentes: stg_registro_diario + dims
-- ============================================================

WITH registro AS (
    SELECT * FROM "aqua_dw"."dm_staging"."stg_registro_diario"
),

dim_p AS (
    SELECT * FROM "aqua_dw"."dm_dm"."dim_poza"
),

dim_l AS (
    SELECT * FROM "aqua_dw"."dm_dm"."dim_lote"
),

dim_t AS (
    SELECT * FROM "aqua_dw"."dm_dm"."dim_tiempo"
),

dim_c AS (
    SELECT * FROM "aqua_dw"."dm_dm"."dim_condicion"
),

hechos AS (

    SELECT
        -- Claves foráneas a dimensiones
        t.sk_fecha,
        p.sk_poza,
        l.sk_lote,
        c.sk_condicion,

        -- Métricas aditivas
        r.kg_alimento,
        r.cantidad_bajas,

        -- Métrica semi-aditiva
        r.temp_promedio,

        -- Métrica calculada: tasa de mortalidad
        ROUND(
            r.cantidad_bajas::NUMERIC / NULLIF(l.poblacion_inicial, 0),
            6
        )                                       AS tasa_mortalidad

    FROM registro r
    JOIN dim_t t ON t.fecha    = r.fecha
    JOIN dim_p p ON p.id_poza  = r.id_poza
    JOIN dim_l l ON l.id_lote  = r.id_lote
    JOIN dim_c c ON (
        r.temp_promedio IS NOT NULL
        AND r.temp_promedio >= c.temp_min
        AND r.temp_promedio <  c.temp_max
    )

)

SELECT * FROM hechos