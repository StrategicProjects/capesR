## Converts the CAPES "Catálogo de Teses e Dissertações" yearly files into the
## parquet files distributed by the package (<out dir>/capes_<year>.parquet):
## the 12 original columns plus the knowledge-area columns (names and codes)
## added in capesR 0.3.0.
##
## Source: https://dadosabertos.capes.gov.br/group/catalogo-de-teses-e-dissertacoes-brasil
## CAPES publishes every year as XLSX and as CSV. The XLSX (dados_xlsx/capes_<year>.xlsx)
## is preferred: the CSV export is lossy (characters outside windows-1252, such
## as Greek letters, are replaced by "?", and a few records are truncated). The
## CSV (dados_raw/capes_<year>.csv) is only used when there is no XLSX.
##
## Usage: Rscript data-raw/build_parquet.R 2023 2024   (or no args = all years present)
## Output dir: env var CAPES_PARQUET_DIR, default "dados_parquet_v2" (kept apart
## from dados_parquet/, the files validated by capesR <= 0.2.1).
##
## CAPES publishes two layouts (the CSVs are ';'-separated and windows-1252 encoded):
##   - 1987-2012 ("legacy"): CamelCase header, no subarea / specialty /
##     concentration area (those columns are NA for these years);
##   - 2013 onwards ("modern"): AN_BASE, NM_*, CD_* header.

suppressPackageStartupMessages({
  library(readr); library(dplyr); library(arrow)
})

out_dir <- Sys.getenv("CAPES_PARQUET_DIR", "dados_parquet_v2")

# package column -> CSV column, per layout. NA = not available in that layout.
col_map <- list(
  modern = c(
    ano_base             = "AN_BASE",
    ies                  = "NM_ENTIDADE_ENSINO",
    area                 = "NM_AREA_AVALIACAO",
    nome_programa        = "NM_PROGRAMA",
    tipo                 = "NM_SUBTIPO_PRODUCAO",
    titulo               = "NM_PRODUCAO",
    resumo               = "DS_RESUMO",
    idioma               = "NM_IDIOMA",
    autoria              = "NM_DISCENTE",
    orientacao           = "NM_ORIENTADOR",
    regiao               = "NM_REGIAO",
    uf                   = "SG_UF_IES",
    grande_area          = "NM_GRANDE_AREA_CONHECIMENTO",
    cd_grande_area       = "CD_GRANDE_AREA_CONHECIMENTO",
    area_conhecimento    = "NM_AREA_CONHECIMENTO",
    cd_area_conhecimento = "CD_AREA_CONHECIMENTO",
    subarea              = "NM_SUBAREA_CONHECIMENTO",
    cd_subarea           = "CD_SUBAREA_CONHECIMENTO",
    especialidade        = "NM_ESPECIALIDADE",
    cd_especialidade     = "CD_ESPECIALIDADE",
    area_concentracao    = "NM_AREA_CONCENTRACAO"
  ),
  legacy = c(
    ano_base             = "AnoBase",
    ies                  = "NomeIes",
    # The 1987-2012 files of capesR <= 0.2.1 had AreaConhecimento here; `area`
    # is now the evaluation area in every year, as in 2013 onwards, and the
    # knowledge area is in `area_conhecimento`.
    area                 = "AreaAvaliacao",
    nome_programa        = "NomePrograma",
    tipo                 = "Nivel",
    titulo               = "TituloTese",
    resumo               = "ResumoTese",
    idioma               = "Idioma",
    autoria              = "Autor",
    orientacao           = "Orientador_1",   # Orientador_2..4 are almost always empty
    regiao               = "Regiao",
    uf                   = "Uf",
    grande_area          = "GrandeAreaDescricao",
    cd_grande_area       = "GrandeAreaCodigo",
    area_conhecimento    = "AreaConhecimento",
    cd_area_conhecimento = "AreaConhecimentoCodigo",
    subarea              = NA,
    cd_subarea           = NA,
    especialidade        = NA,
    cd_especialidade     = NA,
    area_concentracao    = NA
  )
)
stopifnot(identical(names(col_map$modern), names(col_map$legacy)))

# The CSVs are windows-1252, which iconv implementations handle differently
# for the five undefined bytes. Read as latin1 (always valid) and move the C1
# control range U+0080-U+009F to the characters windows-1252 assigns to it
# (curly quotes, dashes, ellipsis...). Undefined bytes are left untouched.
# A few of these control characters are also present in the XLSX cells.
c1_from <- intToUtf8(c(0x80, 0x82:0x8C, 0x8E, 0x91:0x9C, 0x9E, 0x9F))
c1_to <- intToUtf8(c(
  0x20AC, 0x201A, 0x0192, 0x201E, 0x2026, 0x2020, 0x2021, 0x02C6, 0x2030,
  0x0160, 0x2039, 0x0152, 0x017D, 0x2018, 0x2019, 0x201C, 0x201D, 0x2022,
  0x2013, 0x2014, 0x02DC, 0x2122, 0x0161, 0x203A, 0x0153, 0x017E, 0x0178
))
fix_cp1252 <- function(x) chartr(c1_from, c1_to, x)

read_capes_csv <- function(csv, ...) {
  read_delim(csv, delim = ";", locale = locale(encoding = "latin1"),
             col_types = cols(.default = col_character()), progress = FALSE,
             show_col_types = FALSE, ...)
}

read_capes_xlsx <- function(xlsx, ...) {
  readxl::read_excel(xlsx, col_types = "text", .name_repair = "minimal", ...)
}

build_year <- function(year) {
  xlsx <- file.path("dados_xlsx", sprintf("capes_%s.xlsx", year))
  csv <- file.path("dados_raw", sprintf("capes_%s.csv", year))
  out <- file.path(out_dir, sprintf("capes_%s.parquet", year))
  from_xlsx <- file.exists(xlsx)
  if (from_xlsx) csv <- xlsx   # `csv` is the source file from here on
  stopifnot(file.exists(csv))
  header <- names(if (from_xlsx) read_capes_xlsx(csv, n_max = 0) else read_capes_csv(csv, n_max = 0))
  layout <- if ("AN_BASE" %in% header) "modern" else if ("AnoBase" %in% header) "legacy" else
    stop("unknown CSV layout in ", csv)
  map <- col_map[[layout]]
  src <- map[!is.na(map)]
  missing <- setdiff(src, header)
  if (length(missing) > 0) stop(csv, " lacks column(s): ", paste(missing, collapse = ", "))
  message("Reading ", csv, " (", layout, " layout)")

  # Legacy files are read whole so that fully duplicated records can be dropped
  # (as in the files published so far); modern files only need the mapped columns.
  raw <- if (from_xlsx) read_capes_xlsx(csv) else if (layout == "legacy") read_capes_csv(csv) else
    read_capes_csv(csv, col_select = all_of(unname(src)))

  # CAPES CSVs occasionally have rows that are short of columns: a broken quote
  # in the abstract that swallows the trailing columns (1 row in 2021), or
  # records truncated at the source (14 rows in 2017, 13 in 2018, 1 in 2020).
  # Their missing columns become NA. Tolerate a handful of such rows as long
  # as year, institution and title are filled; fail on anything larger.
  pr <- if (from_xlsx) data.frame() else problems(raw)
  if (nrow(pr) > 0) {
    message("  ", nrow(pr), " parse problem(s) in ", csv, " (rows ", paste(unique(pr$row), collapse = ","), ")")
    print(pr)
    # `row` counts the header line, so check both candidates for the data row
    idx <- unique(c(pr$row - 1, pr$row))
    bad <- raw[idx[idx >= 1 & idx <= nrow(raw)], src[c("ano_base", "ies", "titulo")]]
    if (nrow(pr) > 50 || anyNA(bad)) stop("parse problems in ", csv)
  }

  if (layout == "legacy") {
    n0 <- nrow(raw)
    raw <- distinct(raw)
    if (nrow(raw) < n0) message("  dropped ", n0 - nrow(raw), " fully duplicated row(s)")
  }

  d <- raw |> select(all_of(src))
  for (col in names(map)[is.na(map)]) d[[col]] <- NA_character_
  d <- d |>
    select(all_of(names(map))) |>
    # quoted fields keep their padding (e.g. " SOCIOLOGIA" in 2012): trim it
    mutate(across(where(is.character), ~ trimws(fix_cp1252(.x))),
           ano_base = as.numeric(ano_base))
  stopifnot(nrow(d) > 0, !anyNA(d$ano_base), all(d$ano_base == as.numeric(year)))
  message("  ", nrow(d), " rows x ", ncol(d), " cols -> ", out)
  write_parquet(d, out, compression = "snappy")
  invisible(d)
}

years <- commandArgs(trailingOnly = TRUE)
if (length(years) == 0) {
  files <- c(list.files("dados_xlsx", "^capes_\\d{4}\\.xlsx$"), list.files("dados_raw", "^capes_\\d{4}\\.csv$"))
  years <- sort(unique(sub("^capes_(\\d{4})\\..*$", "\\1", files)))
}
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)
for (y in years) build_year(y)
