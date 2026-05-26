-- ============================================================
--  staging.stg_poza
--  Limpieza y tipado de pozas desde raw
--  Fuente: raw.poza (réplica de oltp.poza vía Airbyte)
--          o directamente oltp.poza vía FDW
-- ============================================================

WITH fuente AS (

    -- Airbyte replica en JSONB, extraemos cada campo
    SELECT
        _airbyte_data->>'id_poza'      AS id_poza,
        _airbyte_data->>'nombre_poza'  AS nombre_poza,
        _airbyte_data->>'sector'       AS sector,
        _airbyte_data->>'capacidad_m3' AS capacidad_m3_raw,
        _airbyte_data->>'estado'       AS estado,
        _airbyte_emitted_at            AS cargado_en
    FROM "aqua_dw"."raw"."poza"

),

limpieza AS (

    SELECT
        id_poza,
        TRIM(nombre_poza)                           AS nombre_poza,
        TRIM(sector)                                AS sector,
        'AquaGestión Puno'                          AS granja,
        CAST(capacidad_m3_raw AS NUMERIC(8,2))      AS capacidad_m3,
        COALESCE(estado, 'Activa')                  AS estado,
        cargado_en
    FROM fuente
    WHERE id_poza IS NOT NULL
      AND nombre_poza IS NOT NULL

)

SELECT * FROM limpieza