-- ============================================================
--  AquaGestión Lite — SCRIPT 03
--  Crear DataMart — Esquema Estrella
--  Motor: PostgreSQL | Esquema: dm
--  Ejecutar después de: 02_cargar_datos_oltp.sql
-- ============================================================
--
--  MODELO DIMENSIONAL (Star Schema):
--  ├── dm.dim_tiempo        → Calendario diario (Ene–Jun 2025)
--  ├── dm.dim_poza          → Pozas de crianza (SCD Tipo 1)
--  ├── dm.dim_lote          → Lotes de peces sembrados
--  ├── dm.dim_condicion     → Clasificación por temperatura del Titicaca
--  └── dm.h_registro_diario → Tabla de hechos (día × poza × lote)
-- ============================================================


-- ============================================================
--  0. CREAR ESQUEMA
-- ============================================================

CREATE SCHEMA IF NOT EXISTS dm;

COMMENT ON SCHEMA dm IS
'Data Mart dimensional de AquaGestión Lite.
Modelo estrella: 4 dimensiones + 1 tabla de hechos.
Periodo: Enero–Junio 2025.';


-- ============================================================
--  LIMPIAR (si se re-ejecuta el script)
-- ============================================================

DROP TABLE IF EXISTS dm.h_registro_diario CASCADE;
DROP TABLE IF EXISTS dm.dim_tiempo        CASCADE;
DROP TABLE IF EXISTS dm.dim_poza          CASCADE;
DROP TABLE IF EXISTS dm.dim_lote          CASCADE;
DROP TABLE IF EXISTS dm.dim_condicion     CASCADE;


-- ============================================================
--  1. DIMENSIÓN TIEMPO
-- ============================================================

CREATE TABLE dm.dim_tiempo (
    sk_fecha         CHAR(8)      NOT NULL,  -- surrogate key: YYYYMMDD
    fecha            DATE         NOT NULL,
    dia              SMALLINT     NOT NULL,
    nombre_dia       VARCHAR(15)  NOT NULL,
    es_fin_semana    BOOLEAN      NOT NULL DEFAULT FALSE,
    semana_iso       SMALLINT     NOT NULL,
    mes              SMALLINT     NOT NULL,
    nombre_mes       VARCHAR(15)  NOT NULL,
    trimestre        SMALLINT     NOT NULL,
    nombre_trimestre VARCHAR(10)  NOT NULL,  -- 'Q1', 'Q2', etc.
    semestre         SMALLINT     NOT NULL,
    anio             SMALLINT     NOT NULL,
    es_feriado       BOOLEAN      NOT NULL DEFAULT FALSE,
    nombre_feriado   VARCHAR(60)  NULL,

    CONSTRAINT pk_dim_tiempo       PRIMARY KEY (sk_fecha),
    CONSTRAINT ck_tiempo_mes       CHECK (mes BETWEEN 1 AND 12),
    CONSTRAINT ck_tiempo_trimestre CHECK (trimestre BETWEEN 1 AND 4),
    CONSTRAINT ck_tiempo_semestre  CHECK (semestre BETWEEN 1 AND 2),
    CONSTRAINT ck_tiempo_dia       CHECK (dia BETWEEN 1 AND 31)
);

COMMENT ON TABLE  dm.dim_tiempo          IS 'Dimensión calendario con granularidad diaria. Cubre Ene–Jun 2025.';
COMMENT ON COLUMN dm.dim_tiempo.sk_fecha IS 'Surrogate key en formato YYYYMMDD. Ej: 20250115';


-- ============================================================
--  2. DIMENSIÓN POZA (SCD Tipo 1)
-- ============================================================

CREATE TABLE dm.dim_poza (
    sk_poza      SERIAL       NOT NULL,
    id_poza      VARCHAR(20)  NOT NULL,  -- natural key del OLTP
    nombre_poza  VARCHAR(60)  NOT NULL,
    sector       VARCHAR(40)  NOT NULL,
    granja       VARCHAR(60)  NOT NULL DEFAULT 'AquaGestión Puno',
    capacidad_m3 NUMERIC(8,2) NULL,
    estado       VARCHAR(20)  NOT NULL DEFAULT 'Activa',

    CONSTRAINT pk_dim_poza       PRIMARY KEY (sk_poza),
    CONSTRAINT uq_dim_poza_nk    UNIQUE (id_poza),
    CONSTRAINT ck_poza_estado    CHECK (estado IN ('Activa', 'Baja', 'Mantenimiento')),
    CONSTRAINT ck_poza_capacidad CHECK (capacidad_m3 > 0)
);

COMMENT ON TABLE  dm.dim_poza        IS 'Dimensión pozas de crianza. SCD Tipo 1 (sin historial de cambios).';
COMMENT ON COLUMN dm.dim_poza.sector IS 'Comunidad del Lago Titicaca: Chucuito, Pomata, Juli, Ilave, etc.';


-- ============================================================
--  3. DIMENSIÓN LOTE
-- ============================================================

CREATE TABLE dm.dim_lote (
    sk_lote           SERIAL      NOT NULL,
    id_lote           VARCHAR(20) NOT NULL,  -- natural key del OLTP
    nombre_lote       VARCHAR(60) NOT NULL,
    especie           VARCHAR(40) NOT NULL DEFAULT 'Trucha Arcoíris',
    etapa             VARCHAR(25) NOT NULL,
    fecha_ingreso     DATE        NOT NULL,
    poblacion_inicial INT         NOT NULL,
    proveedor         VARCHAR(80) NULL,

    CONSTRAINT pk_dim_lote       PRIMARY KEY (sk_lote),
    CONSTRAINT uq_dim_lote_nk    UNIQUE (id_lote),
    CONSTRAINT ck_lote_etapa     CHECK (etapa IN ('Alevino', 'Juvenil', 'Engorde')),
    CONSTRAINT ck_lote_poblacion CHECK (poblacion_inicial > 0)
);

COMMENT ON TABLE  dm.dim_lote                   IS 'Dimensión lotes de peces por poza.';
COMMENT ON COLUMN dm.dim_lote.poblacion_inicial IS 'Peces al inicio del lote. Se usa para calcular tasa_mortalidad en el ETL.';
COMMENT ON COLUMN dm.dim_lote.etapa             IS 'Alevino (<5g) / Juvenil (5-50g) / Engorde (>50g)';


-- ============================================================
--  4. DIMENSIÓN CONDICIÓN AMBIENTAL
-- ============================================================

CREATE TABLE dm.dim_condicion (
    sk_condicion      SERIAL       NOT NULL,
    rango_temperatura VARCHAR(30)  NOT NULL,
    temp_min          NUMERIC(5,2) NOT NULL,
    temp_max          NUMERIC(5,2) NOT NULL,
    estado            VARCHAR(25)  NOT NULL,
    color_semaforo    VARCHAR(10)  NOT NULL,  -- código hex para Power BI
    descripcion       VARCHAR(120) NULL,

    CONSTRAINT pk_dim_condicion       PRIMARY KEY (sk_condicion),
    CONSTRAINT uq_dim_condicion_rango UNIQUE (rango_temperatura),
    CONSTRAINT ck_condicion_estado    CHECK (estado IN ('Crítico', 'Bajo', 'Óptimo', 'Alto', 'Muy Alto')),
    CONSTRAINT ck_condicion_temp      CHECK (temp_min < temp_max)
);

COMMENT ON TABLE  dm.dim_condicion                IS 'Clasificación de condición ambiental por temperatura del agua.';
COMMENT ON COLUMN dm.dim_condicion.color_semaforo IS 'Hex para semáforo Power BI: Rojo=#C00000, Naranja=#FF9900, Verde=#00B050, Amarillo=#FFFF00';


-- ============================================================
--  5. TABLA DE HECHOS: h_registro_diario
--     Granularidad: 1 fila por día × poza × lote
-- ============================================================

CREATE TABLE dm.h_registro_diario (
    sk_registro     BIGSERIAL    NOT NULL,
    sk_fecha        CHAR(8)      NOT NULL,
    sk_poza         INT          NOT NULL,
    sk_lote         INT          NOT NULL,
    sk_condicion    INT          NOT NULL,

    -- Métricas aditivas (se suman en cualquier dimensión)
    kg_alimento     NUMERIC(10,3) NOT NULL DEFAULT 0,
    cantidad_bajas  INT           NOT NULL DEFAULT 0,

    -- Métrica semi-aditiva (promediar, nunca sumar entre pozas)
    temp_promedio   NUMERIC(5,2)  NULL,

    -- Métrica calculada en ETL: bajas / poblacion_inicial
    tasa_mortalidad NUMERIC(8,6)  NOT NULL DEFAULT 0,

    CONSTRAINT pk_h_registro      PRIMARY KEY (sk_registro),
    CONSTRAINT fk_hreg_tiempo     FOREIGN KEY (sk_fecha)     REFERENCES dm.dim_tiempo    (sk_fecha),
    CONSTRAINT fk_hreg_poza       FOREIGN KEY (sk_poza)      REFERENCES dm.dim_poza      (sk_poza),
    CONSTRAINT fk_hreg_lote       FOREIGN KEY (sk_lote)      REFERENCES dm.dim_lote      (sk_lote),
    CONSTRAINT fk_hreg_condicion  FOREIGN KEY (sk_condicion) REFERENCES dm.dim_condicion (sk_condicion),
    CONSTRAINT uq_hreg_grano      UNIQUE (sk_fecha, sk_poza, sk_lote),
    CONSTRAINT ck_hreg_alimento   CHECK (kg_alimento >= 0),
    CONSTRAINT ck_hreg_bajas      CHECK (cantidad_bajas >= 0),
    CONSTRAINT ck_hreg_mortalidad CHECK (tasa_mortalidad BETWEEN 0 AND 1)
);

COMMENT ON TABLE  dm.h_registro_diario                IS 'Tabla de hechos. Granularidad: día × poza × lote.';
COMMENT ON COLUMN dm.h_registro_diario.kg_alimento    IS 'Métrica aditiva: kg de alimento del día.';
COMMENT ON COLUMN dm.h_registro_diario.cantidad_bajas IS 'Métrica aditiva: peces muertos en el día.';
COMMENT ON COLUMN dm.h_registro_diario.temp_promedio  IS 'Métrica semi-aditiva: temperatura media del agua (no sumar entre pozas).';
COMMENT ON COLUMN dm.h_registro_diario.tasa_mortalidad IS 'Calculada en ETL: bajas / poblacion_inicial. Rango: 0.000000–1.000000.';


-- ============================================================
--  6. ÍNDICES DE RENDIMIENTO
-- ============================================================

CREATE INDEX idx_hreg_fecha      ON dm.h_registro_diario (sk_fecha);
CREATE INDEX idx_hreg_poza       ON dm.h_registro_diario (sk_poza);
CREATE INDEX idx_hreg_lote       ON dm.h_registro_diario (sk_lote);
CREATE INDEX idx_hreg_condicion  ON dm.h_registro_diario (sk_condicion);
CREATE INDEX idx_hreg_mortalidad ON dm.h_registro_diario (sk_fecha, sk_poza, tasa_mortalidad);


-- ============================================================
--  7. VERIFICACIÓN
-- ============================================================

SELECT
    table_name          AS tabla,
    COUNT(column_name)  AS num_columnas
FROM information_schema.columns
WHERE table_schema = 'dm'
GROUP BY table_name
ORDER BY table_name;

-- Resultado esperado:
-- dim_condicion     | 7
-- dim_lote          | 8
-- dim_poza          | 7
-- dim_tiempo        | 14
-- h_registro_diario | 9
