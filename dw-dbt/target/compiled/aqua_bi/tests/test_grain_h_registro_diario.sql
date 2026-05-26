-- ============================================================
--  Test: sin duplicados en la tabla de hechos
--  Granularidad: 1 fila por día × poza × lote
--  Resultado esperado: 0 filas (sin duplicados)
-- ============================================================

SELECT
    sk_fecha,
    sk_poza,
    sk_lote,
    COUNT(*) AS repeticiones
FROM "aqua_dw"."dm_dm"."h_registro_diario"
GROUP BY sk_fecha, sk_poza, sk_lote
HAVING COUNT(*) > 1