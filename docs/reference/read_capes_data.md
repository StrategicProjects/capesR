# Read and filter data from the CAPES Catalog of Theses and Dissertations

This function combines data from multiple Parquet files and applies
optional filters, including text-based searches.

## Usage

``` r
read_capes_data(files, filters = list())

ler_dados_capes(files, filters = list())
```

## Arguments

- files:

  A vector or list of paths to Parquet files.

- filters:

  A named list of filters. Values for the text columns \`titulo\` and
  \`resumo\` (or \`title\`/\`abstract\`) are matched as case-insensitive
  substrings, and a vector of terms keeps the rows containing any of
  them (e.g., \`list(titulo = c("varicela", "catapora"))\`); all other
  columns are matched exactly (e.g., \`list(ano_base = 1987, uf = "SP",
  titulo = "educação")\`).

## Value

A \`data.frame\` containing the combined and filtered data.

## Columns

The yearly files have one row per thesis or dissertation and the columns
below (names in Portuguese, as in the CAPES source):

- ano_base:

  Reference year.

- ies:

  Higher education institution.

- area:

  Evaluation area (\*área de avaliação\*).

- nome_programa:

  Graduate program.

- tipo:

  Type of work (e.g. master's dissertation, doctoral thesis).

- titulo, resumo:

  Title and abstract.

- idioma:

  Language of the work.

- autoria, orientacao:

  Author and advisor.

- regiao, uf:

  Region and state of the institution.

- grande_area, cd_grande_area:

  Broad knowledge area (\*grande área de conhecimento\*): name and CAPES
  code.

- area_conhecimento, cd_area_conhecimento:

  Knowledge area: name and code.

- subarea, cd_subarea:

  Knowledge subarea: name and code (2013 onwards).

- especialidade, cd_especialidade:

  Specialty: name and code (2013 onwards).

- area_concentracao:

  Concentration area of the program (2013 onwards).

The codes are stored as text. CAPES does not publish subarea, specialty
and concentration area for 1987-2012, so those columns are \`NA\` in
these years.

## Examples

``` r
# \donttest{
# Download data for the years 1987 and 1990
capes_files <- download_capes_data(c(1987, 1990))
#> File already exists: /var/folders/j9/7g_srh2x0d71c5q0pbj5mxh40000gn/T//RtmpsIBZXJ/capes_1987.parquet
#> File already exists: /var/folders/j9/7g_srh2x0d71c5q0pbj5mxh40000gn/T//RtmpsIBZXJ/capes_1990.parquet
# Combine all selected data
combined_data <- read_capes_data(capes_files)
# }
```
