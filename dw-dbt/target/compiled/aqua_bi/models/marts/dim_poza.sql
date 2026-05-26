-- ============================================================
--  dm.dim_poza
--  Dimensión de pozas de crianza
--  Fuente: staging.stg_poza
--  SCD Tipo 1: sobrescribe cambios
-- ============================================================

WITH stg AS (
    SELECT * FROM "aqua_dw"."dm_staging"."stg_poza"
)

SELECT
    ROW_NUMBER() OVER (ORDER BY id_poza)    AS sk_poza,
    id_poza,
    nombre_poza,
    sector,
    granja,
    capacidad_m3,
    estado
FROM stg