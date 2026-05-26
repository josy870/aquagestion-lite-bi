
  create view "aqua_dw"."dm_staging"."stg_lote__dbt_tmp"
    
    
  as (
    -- ============================================================
--  staging.stg_lote
--  Limpieza y tipado de lotes desde raw
--  Fuente: raw.lote (réplica de oltp.lote vía Airbyte)
-- ============================================================

WITH fuente AS (

    SELECT
        _airbyte_data->>'id_lote'           AS id_lote,
        _airbyte_data->>'nombre_lote'       AS nombre_lote,
        _airbyte_data->>'id_poza'           AS id_poza,
        _airbyte_data->>'especie'           AS especie,
        _airbyte_data->>'etapa'             AS etapa,
        _airbyte_data->>'fecha_ingreso'     AS fecha_ingreso_raw,
        _airbyte_data->>'poblacion_inicial' AS poblacion_inicial_raw,
        _airbyte_data->>'proveedor'         AS proveedor,
        _airbyte_emitted_at                 AS cargado_en
    FROM "aqua_dw"."raw"."lote"

),

limpieza AS (

    SELECT
        id_lote,
        TRIM(nombre_lote)                               AS nombre_lote,
        id_poza,
        COALESCE(TRIM(especie), 'Trucha Arcoíris')      AS especie,
        TRIM(etapa)                                     AS etapa,
        CAST(fecha_ingreso_raw AS DATE)                 AS fecha_ingreso,
        CAST(poblacion_inicial_raw AS INT)              AS poblacion_inicial,
        TRIM(proveedor)                                 AS proveedor,
        cargado_en
    FROM fuente
    WHERE id_lote IS NOT NULL
      AND poblacion_inicial_raw IS NOT NULL
      AND CAST(poblacion_inicial_raw AS INT) > 0

)

SELECT * FROM limpieza
  );