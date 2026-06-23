# Documentación MkDocs — AquaGestión Lite BI

Sitio de guías para construir la solución BI end-to-end.

## Uso local

```bash
pip install -r requirements.txt
mkdocs serve          # vista previa en http://127.0.0.1:8000
mkdocs build          # genera la carpeta site/ (estática)
```

## Publicar en GitHub Pages

**Opción A — automática (recomendada):** el workflow `.github/workflows/deploy-docs.yml`
publica el sitio en cada push a `main`. Luego, en GitHub: *Settings → Pages →
Source: Deploy from a branch → rama `gh-pages`*.

**Opción B — manual:**

```bash
mkdocs gh-deploy --force
```

La URL quedará como: `https://tu-usuario.github.io/aquagestion-lite-bi/`

## Antes de entregar

1. En `mkdocs.yml`, reemplaza `[tu nombre]` y `repo_url` por los reales.
2. Agrega tus capturas en cada guía (busca los bloques *Evidencia para el informe*).
3. Verifica que `mkdocs build` no muestre advertencias de enlaces rotos.
