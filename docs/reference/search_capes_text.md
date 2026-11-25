# Search for terms in text fields of the CAPES Catalog of Theses and Dissertations data

Searches one or more terms in one or more text columns of a previously
loaded \`data.frame\`. Matching is literal (not a regular expression)
and case-insensitive.

## Usage

``` r
search_capes_text(data, term, field, match = c("any", "all"))

buscar_texto_capes(data, term, field, match = c("any", "all"))
```

## Arguments

- data:

  A \`data.frame\` containing the CAPES Catalog of Theses and
  Dissertations data.

- term:

  A character vector with one or more terms to search for.

- field:

  A character vector with the name(s) of the column(s) to search in
  (e.g., \`"titulo"\`, \`c("titulo", "resumo")\`).

- match:

  How several terms combine: \`"any"\` (default) keeps rows where at
  least one term occurs in at least one field; \`"all"\` keeps rows
  where every term occurs (each in at least one of the fields).

## Value

A \`data.frame\` with the matching rows. When nothing matches, an empty
\`data.frame\` with the same columns as \`data\` is returned with a
message.

## Examples

``` r
# \donttest{
# Download data for the years 1987 and 1990
capes_files <- download_capes_data(c(1987, 1990))
#> File already exists: /var/folders/j9/7g_srh2x0d71c5q0pbj5mxh40000gn/T//RtmpsIBZXJ/capes_1987.parquet
#> File already exists: /var/folders/j9/7g_srh2x0d71c5q0pbj5mxh40000gn/T//RtmpsIBZXJ/capes_1990.parquet
# Combine all selected data
combined_data <- read_capes_data(capes_files)
# Titles mentioning "Educação"
results <- search_capes_text(combined_data, term = "Educação", field = "titulo")
#> No results found for the search.
# Titles or abstracts mentioning either synonym
results <- search_capes_text(
  combined_data,
  term = c("varicela", "catapora"),
  field = c("titulo", "resumo")
)
# Abstracts mentioning both terms
results <- search_capes_text(
  combined_data,
  term = c("saúde", "escola"),
  field = "resumo",
  match = "all"
)
#> No results found for the search.
# }
```
