-- ============================================================
--  AquaGestión Lite — SCRIPT 01
--  Crear esquema OLTP (fuente transaccional)
--  Motor: PostgreSQL
--  Ejecutar en: pgAdmin o DBeaver
-- ============================================================
--
--  Este esquema simula los registros que actualmente se
--  llevan en Excel (Pozas.xlsx, Lote_Peces.xlsx, Registro_Diario.xlsx)
--
--  TABLAS:
--  ├── oltp.poza             → Unidades físicas de crianza
--  ├── oltp.lote             → Siembras de peces por poza
--  └── oltp.registro_diario → Métricas operativas diarias
-- ============================================================


-- ============================================================
--  0. CREAR ESQUEMA
-- ============================================================

CREATE SCHEMA IF NOT EXISTS oltp;

COMMENT ON SCHEMA oltp IS
'Esquema transaccional de AquaGestión Lite.
Equivale a los archivos Excel: Pozas.xlsx, Lote_Peces.xlsx, Registro_Diario.xlsx';


-- ============================================================
--  1. TABLA: oltp.poza
--     Equivale a: Pozas.xlsx
-- ============================================================

DROP TABLE IF EXISTS oltp.registro_diario CASCADE;
DROP TABLE IF EXISTS oltp.lote          CASCADE;
DROP TABLE IF EXISTS oltp.poza          CASCADE;

CREATE TABLE oltp.poza (
    id_poza      VARCHAR(20)  NOT NULL,
    nombre_poza  VARCHAR(60)  NOT NULL,
    sector       VARCHAR(40)  NOT NULL,   -- Chucuito, Pomata, Juli, Ilave, etc.
    capacidad_m3 NUMERIC(8,2) NULL,       -- Capacidad en metros cúbicos
    estado       VARCHAR(20)  NOT NULL DEFAULT 'Activa',

    CONSTRAINT pk_poza       PRIMARY KEY (id_poza),
    CONSTRAINT ck_poza_estado CHECK (estado IN ('Activa', 'Baja', 'Mantenimiento'))
);

COMMENT ON TABLE  oltp.poza          IS 'Pozas de crianza de truchas. Fuente: Pozas.xlsx';
COMMENT ON COLUMN oltp.poza.sector   IS 'Comunidad o sector del Lago Titicaca';
COMMENT ON COLUMN oltp.poza.estado   IS 'Estado operativo: Activa / Baja / Mantenimiento';


-- ============================================================
--  2. TABLA: oltp.lote
--     Equivale a: Lote_Peces.xlsx
-- ============================================================

CREATE TABLE oltp.lote (
    id_lote           VARCHAR(20) NOT NULL,
    nombre_lote       VARCHAR(60) NOT NULL,
    id_poza           VARCHAR(20) NOT NULL,   -- Poza donde se sembró el lote
    especie           VARCHAR(40) NOT NULL DEFAULT 'Trucha Arcoíris',
    etapa             VARCHAR(25) NOT NULL,   -- Alevino / Juvenil / Engorde
    fecha_ingreso     DATE        NOT NULL,
    poblacion_inicial INT         NOT NULL,
    proveedor         VARCHAR(80) NULL,       -- FONDEPES, PRODUCE, Inka Trout, etc.

    CONSTRAINT pk_lote           PRIMARY KEY (id_lote),
    CONSTRAINT fk_lote_poza      FOREIGN KEY (id_poza) REFERENCES oltp.poza (id_poza),
    CONSTRAINT ck_lote_etapa     CHECK (etapa IN ('Alevino', 'Juvenil', 'Engorde')),
    CONSTRAINT ck_lote_poblacion CHECK (poblacion_inicial > 0)
);

COMMENT ON TABLE  oltp.lote                   IS 'Lotes de peces sembrados por poza. Fuente: Lote_Peces.xlsx';
COMMENT ON COLUMN oltp.lote.poblacion_inicial IS 'Número de peces al inicio del lote (para calcular tasa de mortalidad)';
COMMENT ON COLUMN oltp.lote.etapa             IS 'Alevino (<5g), Juvenil (5-50g), Engorde (>50g)';


-- ============================================================
--  3. TABLA: oltp.registro_diario
--     Equivale a: Registro_Diario.xlsx
-- ============================================================

CREATE TABLE oltp.registro_diario (
    id_registro       BIGSERIAL    NOT NULL,
    fecha             DATE         NOT NULL,
    id_poza           VARCHAR(20)  NOT NULL,
    id_lote           VARCHAR(20)  NOT NULL,
    kg_alimento       NUMERIC(10,3) NOT NULL DEFAULT 0,
    cantidad_bajas    INT           NOT NULL DEFAULT 0,
    temp_promedio     NUMERIC(5,2)  NULL,     -- °C, temperatura media del agua ese día
    observaciones     TEXT          NULL,

    CONSTRAINT pk_registro        PRIMARY KEY (id_registro),
    CONSTRAINT fk_reg_poza        FOREIGN KEY (id_poza) REFERENCES oltp.poza (id_poza),
    CONSTRAINT fk_reg_lote        FOREIGN KEY (id_lote) REFERENCES oltp.lote (id_lote),
    CONSTRAINT uq_reg_grano       UNIQUE (fecha, id_poza, id_lote),
    CONSTRAINT ck_reg_alimento    CHECK (kg_alimento >= 0),
    CONSTRAINT ck_reg_bajas       CHECK (cantidad_bajas >= 0)
);

COMMENT ON TABLE  oltp.registro_diario              IS 'Registro operativo diario por poza y lote. Fuente: Registro_Diario.xlsx';
COMMENT ON COLUMN oltp.registro_diario.temp_promedio IS 'Temperatura promedio del agua ese día (°C). Rango típico Titicaca: 10-16°C';
COMMENT ON COLUMN oltp.registro_diario.cantidad_bajas IS 'Número de peces muertos ese día en la poza';


-- ============================================================
--  4. VERIFICACIÓN
-- ============================================================

SELECT
    table_name                          AS tabla,
    COUNT(column_name)                  AS num_columnas
FROM information_schema.columns
WHERE table_schema = 'oltp'
GROUP BY table_name
ORDER BY table_name;

-- Resultado esperado:
-- lote             | 8
-- poza             | 5
-- registro_diario  | 9
