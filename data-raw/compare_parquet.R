## Compares the rebuilt parquet files (dados_parquet_v2/, 21 columns) with the
## files published for capesR <= 0.2.1 (dados_parquet/, 12 columns), year by
## year, to catch silent regressions in the 12 original columns.
##
## Usage: Rscript data-raw/compare_parquet.R [years]   (no args = 1987:2024)
##
## Expected differences:
##   - `area` in 1987-2012: was the knowledge area, now the evaluation area
##     (the old value must equal the new `area_conhecimento`);
##   - text columns: C1 control characters replaced by the windows-1252
##     characters they stand for (reported as "only encoding");
##   - a few rows added/removed where CAPES revised the CSV.

suppressPackageStartupMessages({library(arrow); library(dplyr)})

old12 <- c("ano_base", "ies", "area", "nome_programa", "tipo", "titulo", "resumo",
           "idioma", "autoria", "orientacao", "regiao", "uf")
same <- function(a, b) (is.na(a) & is.na(b)) | (!is.na(a) & !is.na(b) & a == b)
c1_from <- intToUtf8(c(0x80, 0x82:0x8C, 0x8E, 0x91:0x9C, 0x9E, 0x9F))
c1_to <- intToUtf8(c(
  0x20AC, 0x201A, 0x0192, 0x201E, 0x2026, 0x2020, 0x2021, 0x02C6, 0x2030,
  0x0160, 0x2039, 0x0152, 0x017D, 0x2018, 0x2019, 0x201C, 0x201D, 0x2022,
  0x2013, 0x2014, 0x02DC, 0x2122, 0x0161, 0x203A, 0x0153, 0x017E, 0x0178))

years <- commandArgs(trailingOnly = TRUE)
if (length(years) == 0) years <- 1987:2024
res <- list()
for (y in years) {
  o <- read_parquet(sprintf("dados_parquet/capes_%s.parquet", y))
  n <- read_parquet(sprintf("dados_parquet_v2/capes_%s.parquet", y))
  r <- list(ano = y, antigo = nrow(o), novo = nrow(n), alinhado = nrow(o) == nrow(n))
  stopifnot(identical(names(n)[1:12], old12), ncol(n) == 21)
  if (!r$alinhado) {
    # CAPES revised the file: align on author + title + institution
    key <- function(d) paste(d$autoria, d$titulo, d$ies, sep = "\r")
    ko <- chartr(c1_from, c1_to, key(o)); kn <- key(n)
    r$so_antigo <- sum(!ko %in% kn); r$so_novo <- sum(!kn %in% ko)
    io <- which(!duplicated(ko) & ko %in% kn); o <- o[io, ]; n <- n[match(ko[io], kn), ]
  }
  for (v in setdiff(old12, "ano_base")) {
    d <- !same(o[[v]], n[[v]])
    enc <- d & same(chartr(c1_from, c1_to, o[[v]]), n[[v]])
    r[[v]] <- sum(d & !enc); r[[paste0(v, "_enc")]] <- sum(enc)
  }
  r$area_era_conhecimento <- all(same(o$area, n$area_conhecimento))
  res[[length(res) + 1]] <- as.data.frame(r[lengths(r) == 1])
}
out <- bind_rows(res)
out[is.na(out)] <- 0
options(width = 250)
cat("Linhas e diferenças reais (fora codificação) por coluna:\n")
print(out[, c("ano", "antigo", "novo", intersect(c("so_antigo", "so_novo"), names(out)),
              setdiff(old12, "ano_base"), "area_era_conhecimento")], row.names = FALSE)
cat("\nDiferenças só de codificação (C1 -> windows-1252), total por coluna:\n")
print(colSums(out[, grep("_enc$", names(out))]))
cat("\nTotal de linhas: antigo", sum(out$antigo), "novo", sum(out$novo), "\n")
