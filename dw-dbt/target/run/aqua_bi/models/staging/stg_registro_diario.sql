
  create view "aqua_dw"."dm_staging"."stg_registro_diario__dbt_tmp"
    
    
  as (
    -- ============================================================
--  staging.stg_registro_diario
--  Limpieza y tipado del registro diario desde raw
--  Fuente: raw.registro_diario
-- ============================================================

WITH fuente AS (

    SELECT
        _airbyte_data->>'id_registro'    AS id_registro_raw,
        _airbyte_data->>'fecha'          AS fecha_raw,
        _airbyte_data->>'id_poza'        AS id_poza,
        _airbyte_data->>'id_lote'        AS id_lote,
        _airbyte_data->>'kg_alimento'    AS kg_alimento_raw,
        _airbyte_data->>'cantidad_bajas' AS cantidad_bajas_raw,
        _airbyte_data->>'temp_promedio'  AS temp_promedio_raw,
        _airbyte_data->>'observaciones'  AS observaciones,
        _airbyte_emitted_at              AS cargado_en
    FROM "aqua_dw"."raw"."registro_diario"

),

limpieza AS (

    SELECT
        CAST(id_registro_raw AS BIGINT)         AS id_registro,
        CAST(fecha_raw AS DATE)                 AS fecha,
        id_poza,
        id_lote,
        CAST(kg_alimento_raw AS NUMERIC(10,3))  AS kg_alimento,
        CAST(cantidad_bajas_raw AS INT)          AS cantidad_bajas,
        CASE
            WHEN temp_promedio_raw IS NOT NULL
            THEN CAST(temp_promedio_raw AS NUMERIC(5,2))
            ELSE NULL
        END                                     AS temp_promedio,
        observaciones,
        -- Clasificar condición ambiental directamente en staging
        CASE
            WHEN CAST(temp_promedio_raw AS NUMERIC(5,2)) < 10   THEN 'Crítico'
            WHEN CAST(temp_promedio_raw AS NUMERIC(5,2)) < 12   THEN 'Bajo'
            WHEN CAST(temp_promedio_raw AS NUMERIC(5,2)) < 14   THEN 'Óptimo'
            WHEN CAST(temp_promedio_raw AS NUMERIC(5,2)) < 16   THEN 'Alto'
            WHEN CAST(temp_promedio_raw AS NUMERIC(5,2)) >= 16  THEN 'Muy Alto'
            ELSE NULL
        END                                     AS condicion_termica,
        cargado_en
    FROM fuente
    WHERE fecha_raw IS NOT NULL
      AND id_poza IS NOT NULL
      AND id_lote IS NOT NULL
      AND CAST(kg_alimento_raw AS NUMERIC(10,3)) >= 0
      AND CAST(cantidad_bajas_raw AS INT) >= 0

)

SELECT * FROM limpieza
  );