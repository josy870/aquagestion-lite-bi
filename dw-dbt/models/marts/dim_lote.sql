-- ============================================================
--  dm.dim_lote
--  Dimensión de lotes de peces sembrados
--  Fuente: staging.stg_lote
-- ============================================================

WITH stg AS (
    SELECT * FROM {{ ref('stg_lote') }}
)

SELECT
    ROW_NUMBER() OVER (ORDER BY id_lote)    AS sk_lote,
    id_lote,
    nombre_lote,
    especie,
    etapa,
    fecha_ingreso,
    poblacion_inicial,
    proveedor
FROM stg
