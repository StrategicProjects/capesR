# Download CAPES Data

Downloads the yearly Parquet files of the CAPES Catalog of Theses and
Dissertations for the selected years. The file list and download URLs
come from \[capes_years\].

## Usage

``` r
download_capes_data(
  years,
  destination = tempdir(),
  timeout = 120,
  base_url = getOption("capesR.base_url")
)

baixar_dados_capes(
  years,
  destination = tempdir(),
  timeout = 120,
  base_url = getOption("capesR.base_url")
)
```

## Arguments

- years:

  A vector with the desired years (1987-2024).

- destination:

  The directory where the files will be saved (default: temporary
  directory).

- timeout:

  The timeout in seconds for the download process (default: 120
  seconds).

- base_url:

  Optional base URL of a mirror hosting the files listed in
  \[capes_years\]. Defaults to \`getOption("capesR.base_url")\`; when
  \`NULL\`, the \`url\` column of \[capes_years\] is used.

## Value

A named list (by year) of file paths for the downloaded or already
existing files.

## Details

A file already present in \`destination\` is reused only when its size
matches the one recorded in \[capes_years\]; otherwise (for instance, a
file downloaded with an earlier version of the package, which had fewer
columns) it is downloaded again.

## Examples

``` r
# \donttest{
# Download data for the years 1987 and 1990
capes_files <- download_capes_data(c(1987, 1990))
#> Downloading: /var/folders/j9/7g_srh2x0d71c5q0pbj5mxh40000gn/T//RtmpsIBZXJ/capes_1987.parquet
#> Downloading: /var/folders/j9/7g_srh2x0d71c5q0pbj5mxh40000gn/T//RtmpsIBZXJ/capes_1990.parquet
# }
```
