# capesR 0.3.0

* New columns with the CAPES knowledge-area classification, names and codes:
  `grande_area`, `cd_grande_area`, `area_conhecimento`, `cd_area_conhecimento`,
  `subarea`, `cd_subarea`, `especialidade`, `cd_especialidade` and
  `area_concentracao` (#9). The 12 existing columns keep their names and
  position. CAPES does not publish subarea, specialty and concentration area
  for 1987-2012, so these are `NA` in those years. The columns are documented
  in `?read_capes_data`.
* **Breaking change in the data:** `area` is now the evaluation area (*área de
  avaliação*) in every year. In the files for 1987-2012 it used to hold the
  knowledge area, unlike 2013 onwards; that value is now in `area_conhecimento`.
  Code that filters `area` for years up to 2012 will get different results.
* All years were rebuilt from the XLSX files of the CAPES open data portal.
  Curly quotes, dashes and similar characters that were stored as invisible
  control characters in the titles and abstracts of 2013, 2019 and 2021-2024
  are now correct.
* 2017, 2018 and 2020 now follow the files CAPES revised in August 2024: 15
  more records (4 in 2017, 11 in 2018), and typographic quotes and dashes in
  titles and abstracts replaced by their plain equivalents, as in the source.
* The new files are served from a separate folder of the data repository, so
  earlier versions of the package keep working with the files they expect.
* `download_capes_data()` downloads a file again when the copy found in
  `destination` does not have the expected size, e.g. a file saved by an
  earlier version of the package. Previously any existing file was reused.

# capesR 0.2.1

* `search_capes_text()` accepts several terms and several fields (#5,
  hugoavmedeiros/capesR). A row is kept when any of the terms occurs in any of
  the fields, e.g. `search_capes_text(data, c("varicela", "catapora"),
  c("titulo", "resumo"))`; the new `match = "all"` argument requires every term
  instead. Previously a vector in `term` raised an error.
* `read_capes_data()` text filters (`titulo`, `resumo`) also accept a vector of
  terms, matching rows that contain any of them.
* When nothing matches, `search_capes_text()` returns an empty `data.frame` with
  the same columns as the input (previously a `data.frame` with no columns).
* Added unit tests (testthat).
* Repository moved to <https://github.com/StrategicProjects/capesR>, which now
  also holds the history of the original hugoavmedeiros/capesR repository.

# capesR 0.2.0

* Data updated from the CAPES open data portal: years 2023 and 2024 added, and
  2019, 2021 and 2022 replaced by the revised files CAPES published in 2025
  (institution names in those files now use `(CAMPUS)` instead of `( CAMPUS )`).
  The package now covers 1987 through 2024.
* André Leite is now the package maintainer (previously Hugo Vasconcelos Medeiros).
* Data hosting moved off OSF. The yearly Parquet files are now listed in the new
  `capes_years` dataset (year, file, url, bytes, md5), which replaces `years_osf`.
  `download_capes_data()` reads the URL from that table, so the host can change
  without touching the code.
* `download_capes_data()` gains a `base_url` argument (default
  `getOption("capesR.base_url")`) to download from a mirror, downloads to a
  temporary `.part` file first, checks the file size, and warns about requested
  years that are not available.
* `read_capes_data()` text search now works on the actual column names of the
  data (`titulo`, `resumo`); it previously only recognised `title`, so
  `filters = list(titulo = "...")` silently matched nothing.
* `read_capes_data()` no longer loads the whole dataset into memory just to
  read the column names.
* Repository moved to <https://github.com/milkway/capesR>.

# capesR 0.1.0

* Initial CRAN release.
