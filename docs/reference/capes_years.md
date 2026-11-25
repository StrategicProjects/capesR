# Annual files of the CAPES Catalog of Theses and Dissertations

A data frame listing, for each year, the Parquet file distributed by the
package and the URL from which it is downloaded. Used internally by
\[download_capes_data()\]; the host can be overridden with the
\`capesR.base_url\` option (see \[download_capes_data()\]).

## Usage

``` r
capes_years
```

## Format

A data frame with one row per year (1987-2024) and the columns:

- year:

  Year of the data.

- file:

  File name (e.g. \`capes_1987.parquet\`).

- url:

  Download URL of the file.

- bytes:

  File size in bytes, used to check the download.

- md5:

  MD5 checksum of the file.

## Source

Derived from the CAPES open data portal,
\<https://dadosabertos.capes.gov.br/group/catalogo-de-teses-e-dissertacoes-brasil\>.

## Examples

``` r
data(capes_years)
head(capes_years)
#>   year               file
#> 1 1987 capes_1987.parquet
#> 2 1988 capes_1988.parquet
#> 3 1989 capes_1989.parquet
#> 4 1990 capes_1990.parquet
#> 5 1991 capes_1991.parquet
#> 6 1992 capes_1992.parquet
#>                                                                               url
#> 1 https://huggingface.co/datasets/mlkwy/capesR/resolve/main/v2/capes_1987.parquet
#> 2 https://huggingface.co/datasets/mlkwy/capesR/resolve/main/v2/capes_1988.parquet
#> 3 https://huggingface.co/datasets/mlkwy/capesR/resolve/main/v2/capes_1989.parquet
#> 4 https://huggingface.co/datasets/mlkwy/capesR/resolve/main/v2/capes_1990.parquet
#> 5 https://huggingface.co/datasets/mlkwy/capesR/resolve/main/v2/capes_1991.parquet
#> 6 https://huggingface.co/datasets/mlkwy/capesR/resolve/main/v2/capes_1992.parquet
#>     bytes                              md5
#> 1 2619409 2da5c81287fd6d80d34b5611cb1cd722
#> 2 2545749 b9523b36d89668478f630c414c4d9c54
#> 3 3031718 6a2b620f9b08e006b3651207a92c52d7
#> 4 3603034 ee1ec12a10f962f48673cdabde61340c
#> 5 4607703 d7d59725bdec8ba532d57a8cb1ddf388
#> 6 5164955 5c56ac881b2485d85c837baf42339bdd
```
