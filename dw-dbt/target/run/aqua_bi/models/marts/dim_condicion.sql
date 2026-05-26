
  
    

  create  table "aqua_dw"."dm_dm"."dim_condicion__dbt_tmp"
  
  
    as
  
  (
    -- ============================================================
--  dm.dim_condicion
--  Dimensión condición ambiental por temperatura
--  Valores fijos basados en rangos del Lago Titicaca
--  No depende de staging — se genera directamente aquí
-- ============================================================

WITH condiciones AS (

    SELECT *
    FROM (VALUES
        (1, '< 10°C',   -99.00::NUMERIC,  9.99::NUMERIC,  'Crítico',  '#C00000', 'Temperatura muy baja. Alta mortalidad. Peces en estrés severo.'),
        (2, '10–12°C',   10.00::NUMERIC, 11.99::NUMERIC,  'Bajo',     '#FF9900', 'Por debajo del rango óptimo. Crecimiento lento.'),
        (3, '12–14°C',   12.00::NUMERIC, 13.99::NUMERIC,  'Óptimo',   '#00B050', 'Rango óptimo para trucha arcoíris en el Titicaca.'),
        (4, '14–16°C',   14.00::NUMERIC, 15.99::NUMERIC,  'Alto',     '#FFFF00', 'Límite superior tolerable. Monitorear oxígeno.'),
        (5, '> 16°C',    16.00::NUMERIC, 99.99::NUMERIC,  'Muy Alto', '#C00000', 'Temperatura crítica alta. Riesgo de floraciones algales.')
    ) AS t(sk_condicion, rango_temperatura, temp_min, temp_max, estado, color_semaforo, descripcion)

)

SELECT
    sk_condicion,
    rango_temperatura,
    temp_min,
    temp_max,
    estado,
    color_semaforo,
    descripcion
FROM condiciones
  );
  