# dw-pg — PostgreSQL analítico (Data Warehouse)

Contenedor PostgreSQL que actúa como destino analítico del pipeline.
Airbyte replica datos aquí, dbt los transforma, Power BI los consume.

## Arquitectura de schemas

```
aqua_dw (base de datos)
├── raw      ← Bronze: réplica cruda desde OLTP vía Airbyte
├── staging  ← Silver: limpieza y tipado vía dbt
└── dm       ← Gold:   DataMart dimensional para Power BI
```

## Levantar el contenedor

```powershell
# Desde la carpeta dw-pg/
cd aquagestion-lite-bi\dw-pg
docker compose up -d
```

Verificar que está corriendo:
```powershell
docker ps
# Debe aparecer: aqua-dw-pg   postgres:16   0.0.0.0:15432->5432/tcp
```

## Conectar desde pgAdmin

Crear un nuevo servidor con estos datos:

| Campo    | Valor      |
|----------|------------|
| Host     | localhost  |
| Port     | **15432**  |
| Database | aqua_dw    |
| User     | aqua       |
| Password | aqua1234   |

## Verificar schemas creados

En pgAdmin ejecuta:
```sql
SELECT table_schema, table_name
FROM information_schema.tables
WHERE table_schema IN ('raw', 'staging', 'dm')
ORDER BY table_schema, table_name;
```

Resultado esperado: las 3 tablas raw (`poza`, `lote`, `registro_diario`).

## Detener y reiniciar

```powershell
docker compose down        # detiene (conserva datos)
docker compose down -v     # destruye todo (incluyendo datos)
docker compose up -d       # vuelve a levantar
```
