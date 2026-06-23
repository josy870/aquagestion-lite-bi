# 1. OLTP — PostgreSQL 17

## Objetivo

Construir la base transaccional `aquagestion_puno` que registra la operación diaria de la
piscigranja: pozas, proveedores, lotes y el registro diario de producción.

## Prerrequisitos

- PostgreSQL 17 instalado y corriendo en el puerto `5432`.
- VS Code con la extensión *Database Client*.

## Modelo transaccional

| Tabla | Descripción | Campos principales |
| --- | --- | --- |
| `poza` | Pozas/estanques y su ubicación. | `id_poza`, `sector`, `capacidad` |
| `proveedor` | Proveedores de insumos (alevines, alimento). | `id_proveedor`, `nombre`, `tipo` |
| `condicion_sanitaria` | Catálogo de estados sanitarios. | `id_condicion`, `descripcion` |
| `lote` | Lotes de siembra. | `id_lote`, `id_poza`, `id_proveedor`, `fecha_siembra`, `poblacion` |
| `registro_diario` | Registro diario por poza/lote. | `fecha`, `id_poza`, `id_lote`, `alimento_kg`, `bajas`, `temperatura_agua`, `oxigeno` |

!!! note "Sectores y proveedores reales"
    Sectores de la cuenca: **Chucuito, Pomata, Juli, Yunguyo, Ilave**.
    Proveedores institucionales: **FONDEPES, PRODUCE Puno**.

## Pasos

### 1. Crear el esquema

```sql
CREATE SCHEMA IF NOT EXISTS aquagestion_puno;
SET search_path TO aquagestion_puno;
```

### 2. Crear las tablas y cargar datos

Ejecuta los scripts de la carpeta `oltp-pg/` (DDL primero, luego los datos).

!!! tip "Archivos SQL grandes"
    Clic derecho sobre el nombre de la base → **Importar SQL**. Es el método confiable
    para archivos grandes; el editor *Query* aparece directo bajo el nombre de la base.

## Reglas de negocio modeladas

- **Alimentación proporcional**: el alimento se modela como ≈ **1,4 % de la biomasa** del lote.
- **Oxígeno inverso a temperatura**: el oxígeno disuelto baja cuando sube la temperatura.
- **Picos de mortalidad por friaje**: las bajas se incrementan en los eventos de frío.

## Verificación

```sql
SELECT 'poza' AS tabla, COUNT(*) FROM aquagestion_puno.poza
UNION ALL SELECT 'proveedor', COUNT(*) FROM aquagestion_puno.proveedor
UNION ALL SELECT 'condicion_sanitaria', COUNT(*) FROM aquagestion_puno.condicion_sanitaria
UNION ALL SELECT 'lote', COUNT(*) FROM aquagestion_puno.lote
UNION ALL SELECT 'registro_diario', COUNT(*) FROM aquagestion_puno.registro_diario;
```

El `registro_diario` debe rondar los **~7 600 registros**.

!!! success "Evidencia para el informe"
    Captura el resultado del `COUNT(*)` por tabla y un `SELECT` de ejemplo del
    `registro_diario`.
