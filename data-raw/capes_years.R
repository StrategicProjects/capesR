## Builds the `capes_years` index shipped in data/capes_years.rda.
##
## The yearly Parquet files must be present in dados_parquet_v2/ (gitignored;
## built by data-raw/build_parquet.R). The local copy can be restored from the
## current host with:
##   capesR::download_capes_data(1987:2024, destination = "dados_parquet_v2")
##
## To move the data to another host, change `base_url` below, upload the files
## (see data-raw/upload_data.sh) and re-run this script.
##
## History: OSF (https://osf.io/4a5b7/, capesR 0.1.0); Hugging Face, repository
## root (12 columns, capesR 0.2.x, in dados_parquet/ -- those files must stay
## online unchanged, since 0.2.x checks their size); Hugging Face, v2/ folder
## (21 columns, capesR >= 0.3.0).

data_dir <- "dados_parquet_v2"
base_url <- "https://huggingface.co/datasets/mlkwy/capesR/resolve/main/v2"

files <- sort(list.files(data_dir, pattern = "^capes_\\d{4}\\.parquet$"))
stopifnot(length(files) == 38)

capes_years <- data.frame(
  year  = as.integer(sub("^capes_(\\d{4})\\.parquet$", "\\1", files)),
  file  = files,
  url   = paste0(base_url, "/", files),
  bytes = as.numeric(file.size(file.path(data_dir, files))),
  md5   = unname(tools::md5sum(file.path(data_dir, files))),
  stringsAsFactors = FALSE
)

usethis::use_data(capes_years, overwrite = TRUE)
