-- ============================================================
--  AquaGestión Lite — dw-pg
--  Script de inicialización del PostgreSQL analítico
--  Se ejecuta AUTOMÁTICAMENTE cuando el contenedor arranca
--  por primera vez (directorio docker-entrypoint-initdb.d)
-- ============================================================
--
--  ARQUITECTURA DE SCHEMAS (Medallion):
--
--  raw     (Bronze) ← Airbyte replica aquí desde el OLTP
--                     Datos crudos, sin transformar
--
--  staging (Silver) ← dbt transforma raw → staging
--                     Limpieza, tipos, renombres
--
--  dm      (Gold)   ← dbt transforma staging → dm
--                     Dimensiones + tabla de hechos listos para Power BI
-- ============================================================


-- ============================================================
--  1. CREAR LOS 3 SCHEMAS
-- ============================================================

CREATE SCHEMA IF NOT EXISTS raw;
CREATE SCHEMA IF NOT EXISTS staging;
CREATE SCHEMA IF NOT EXISTS dm;

COMMENT ON SCHEMA raw     IS 'Bronze: réplica cruda desde OLTP vía Airbyte. No modificar manualmente.';
COMMENT ON SCHEMA staging IS 'Silver: datos limpios y tipados. Generado por dbt desde raw.';
COMMENT ON SCHEMA dm      IS 'Gold: DataMart dimensional listo para Power BI. Generado por dbt desde staging.';


-- ============================================================
--  2. TABLAS RAW
--     Airbyte las crea automáticamente, pero las definimos
--     aquí para que el schema esté documentado y sea
--     compatible con dbt desde el primer run.
--
--     Naming de Airbyte: _airbyte_raw_<tabla>
--     Columna especial: _airbyte_data (JSONB con la fila original)
-- ============================================================

-- raw.poza — réplica de oltp.poza
CREATE TABLE IF NOT EXISTS raw.poza (
    _airbyte_ab_id          UUID          DEFAULT gen_random_uuid(),
    _airbyte_emitted_at     TIMESTAMPTZ   DEFAULT NOW(),
    _airbyte_data           JSONB         NOT NULL,
    CONSTRAINT pk_raw_poza  PRIMARY KEY (_airbyte_ab_id)
);

-- raw.lote — réplica de oltp.lote
CREATE TABLE IF NOT EXISTS raw.lote (
    _airbyte_ab_id          UUID          DEFAULT gen_random_uuid(),
    _airbyte_emitted_at     TIMESTAMPTZ   DEFAULT NOW(),
    _airbyte_data           JSONB         NOT NULL,
    CONSTRAINT pk_raw_lote  PRIMARY KEY (_airbyte_ab_id)
);

-- raw.registro_diario — réplica de oltp.registro_diario
CREATE TABLE IF NOT EXISTS raw.registro_diario (
    _airbyte_ab_id              UUID          DEFAULT gen_random_uuid(),
    _airbyte_emitted_at         TIMESTAMPTZ   DEFAULT NOW(),
    _airbyte_data               JSONB         NOT NULL,
    CONSTRAINT pk_raw_registro  PRIMARY KEY (_airbyte_ab_id)
);

COMMENT ON TABLE raw.poza             IS 'Réplica cruda de oltp.poza vía Airbyte';
COMMENT ON TABLE raw.lote             IS 'Réplica cruda de oltp.lote vía Airbyte';
COMMENT ON TABLE raw.registro_diario  IS 'Réplica cruda de oltp.registro_diario vía Airbyte';


-- ============================================================
--  3. VERIFICACIÓN
-- ============================================================

SELECT
    table_schema    AS schema,
    table_name      AS tabla
FROM information_schema.tables
WHERE table_schema IN ('raw', 'staging', 'dm')
ORDER BY table_schema, table_name;
