# 6. Power BI — modelo semántico y dashboard

## Objetivo

Conectar Power BI al Data Mart, definir el modelo semántico (relaciones y medidas DAX) y
construir el tablero de 5 páginas con tema verde "Titicaca".

## 1. Conexión y relaciones

Conecta al DW (`localhost:15432`, esquema `dm`) e importa las cinco tablas. Crea las
relaciones **1:*** desde cada dimensión hacia el hecho:

| Dimensión | Hecho | Campo |
| --- | --- | --- |
| `dim_tiempo` | `h_registro_diario` | `sk_fecha` |
| `dim_poza` | `h_registro_diario` | `sk_poza` |
| `dim_lote` | `h_registro_diario` | `sk_lote` |
| `dim_condicion` | `h_registro_diario` | `sk_condicion` |

!!! danger "Marca dim_tiempo como tabla de fechas"
    *Herramientas de tabla → Marcar como tabla de fechas*, apuntando a la columna `fecha`
    (tipo *Date* real, **no** la clave `CHAR(8)`). Sin esto, `SAMEPERIODLASTYEAR` y
    `PREVIOUSMONTH` fallan.

## 2. Medidas DAX

```dax
Total Bajas = SUM(h_registro_diario[bajas])

Consumo Alimento = SUM(h_registro_diario[alimento_kg])

Temperatura Promedio = AVERAGE(h_registro_diario[temperatura_agua])

Tasa de Mortalidad =
DIVIDE([Total Bajas], SUM(dim_lote[poblacion]))

Alimento Año Previo =
CALCULATE([Consumo Alimento], SAMEPERIODLASTYEAR(dim_tiempo[fecha]))

Alimento Mes Anterior =
CALCULATE([Consumo Alimento], PREVIOUSMONTH(dim_tiempo[fecha]))

Var % Año Previo =
DIVIDE([Consumo Alimento] - [Alimento Año Previo], [Alimento Año Previo])
```

!!! note "Ajusta los nombres de columna"
    `bajas`, `alimento_kg`, `temperatura_agua`, `poblacion`, `fecha`: verifícalos contra tu
    modelo real.

## 3. Páginas del dashboard

| Página | Visuales |
| --- | --- |
| Resumen ejecutivo | 4 tarjetas KPI + líneas + medidor |
| Mortalidad | Líneas, ranking por sector, matriz |
| Alimentación | Tendencia, tarjetas, barras |
| Condiciones del agua | Líneas combinadas temperatura/bajas |
| Comparativos | Matriz de control + KPI + tarjetas |

## 4. Comparativos obligatorios

La métrica protagonista es **Consumo de Alimento** (de flujo, sumable):

1. **Actual vs año previo** — línea con `[Consumo Alimento]` y `[Alimento Año Previo]`.
2. **Actual vs periodo anterior** — línea con `[Consumo Alimento]` y `[Alimento Mes Anterior]`.
3. **Variación por dimensión** — matriz por `sector` con `[Var % Año Previo]` y formato condicional.

!!! success "Evidencia para el informe"
    Captura la vista de relaciones, las medidas DAX y cada uno de los tres comparativos.
