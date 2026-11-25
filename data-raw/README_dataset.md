---
license: other
license_name: capes-open-data
license_link: https://dadosabertos.capes.gov.br
language:
  - pt
pretty_name: CAPES Catalog of Theses and Dissertations (1987-2024)
tags:
  - brazil
  - education
  - theses
size_categories:
  - 1M<n<10M
configs:
  - config_name: default
    data_files: "v2/capes_*.parquet"
  - config_name: v1
    data_files: "capes_*.parquet"
---

# CAPES Catalog of Theses and Dissertations, 1987-2024

One Parquet file per year (`capes_1987.parquet` ... `capes_2024.parquet`) derived from the
open data of the Brazilian Coordination for the Improvement of Higher Education Personnel
(CAPES): <https://dadosabertos.capes.gov.br/group/catalogo-de-teses-e-dissertacoes-brasil>.

There are two sets of files:

- **`v2/`** (current, used by capesR 0.3.0 and later): 21 columns, built from the XLSX files
  of the CAPES portal. Columns: `ano_base`, `ies`, `area`, `nome_programa`, `tipo`, `titulo`,
  `resumo`, `idioma`, `autoria`, `orientacao`, `regiao`, `uf`, and the knowledge-area
  classification with names and codes: `grande_area`, `cd_grande_area`, `area_conhecimento`,
  `cd_area_conhecimento`, `subarea`, `cd_subarea`, `especialidade`, `cd_especialidade`,
  `area_concentracao`. `area` is the evaluation area in every year. CAPES does not publish
  subarea, specialty and concentration area for 1987-2012, so those are null in these years.
- **repository root** (frozen, used by capesR 0.2.x): the first 12 columns only. In the files
  for 1987-2012 `area` holds the knowledge area instead of the evaluation area. These files
  are kept unchanged because capesR 0.2.x checks their size.

These files back the R package [capesR](https://github.com/StrategicProjects/capesR)
(`capesR::download_capes_data()`). Maintained by André Leite; original compilation by
Hugo Vasconcelos Medeiros, Dalson Figueiredo Filho and André Leite.
