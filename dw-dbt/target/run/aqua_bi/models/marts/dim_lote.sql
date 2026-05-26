
  
    

  create  table "aqua_dw"."dm_dm"."dim_lote__dbt_tmp"
  
  
    as
  
  (
    -- ============================================================
--  dm.dim_lote
--  Dimensión de lotes de peces sembrados
--  Fuente: staging.stg_lote
-- ============================================================

WITH stg AS (
    SELECT * FROM "aqua_dw"."dm_staging"."stg_lote"
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
  );
  