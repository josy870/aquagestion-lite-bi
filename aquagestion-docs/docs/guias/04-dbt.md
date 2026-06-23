# 4. Transformación — dbt Core 1.7.18

## Objetivo

Transformar la capa `raw` en modelos limpios (`staging`) y luego en el esquema dimensional
(`marts` / `dm`), con pruebas de calidad. Resultado esperado: **8 modelos en PASS**.

## Estructura del proyecto dbt

```text
dw-dbt/
├── docker-compose.yml
├── Dockerfile
├── dbt_project.yml
├── profiles.yml
└── models/
    ├── staging/
    │   ├── stg_poza.sql
    │   ├── stg_lote.sql
    │   └── stg_registro_diario.sql
    └── marts/
        ├── dim_tiempo.sql
        ├── dim_poza.sql
        ├── dim_lote.sql
        ├── dim_condicion.sql
        └── h_registro_diario.sql
```

!!! warning "Dockerfile en Windows: pip en una sola línea"
    Las PowerShell *backticks* corrompen la sintaxis del Dockerfile. Pon todos los paquetes
    pip en **una sola línea `RUN`**:

    ```dockerfile
    RUN pip install --no-cache-dir dbt-core==1.7.18 dbt-postgres==1.7.18
    ```

## Pasos

### 1. Ejecutar las transformaciones

```bash
cd dw-dbt
docker compose run --rm dbt dbt run
```

!!! note "Comando correcto"
    `docker compose run --rm dbt dbt run` — el primer `dbt` es el **servicio** de compose;
    el segundo es el **comando** dbt. No es `dbt dbt run`.

### 2. Ejecutar las pruebas

```bash
docker compose run --rm dbt dbt test
```

## Pruebas de calidad recomendadas

```yaml
# models/marts/schema.yml
models:
  - name: h_registro_diario
    columns:
      - name: sk_fecha
        tests: [not_null]
      - name: sk_poza
        tests:
          - not_null
          - relationships:
              to: ref('dim_poza')
              field: sk_poza
  - name: dim_poza
    columns:
      - name: sk_poza
        tests: [unique, not_null]
```

## Verificación

La salida de `dbt test` debe mostrar **PASS=8, WARN=0, ERROR=0**.

!!! success "Evidencia para el informe"
    Captura la salida de `dbt run` y `dbt test` con todos los modelos en PASS.
