utils::globalVariables(".data")


#' Annual files of the CAPES Catalog of Theses and Dissertations
#'
#' A data frame listing, for each year, the Parquet file distributed by the
#' package and the URL from which it is downloaded. Used internally by
#' [download_capes_data()]; the host can be overridden with the
#' `capesR.base_url` option (see [download_capes_data()]).
#'
#' @format A data frame with one row per year (1987-2024) and the columns:
#' \describe{
#'   \item{year}{Year of the data.}
#'   \item{file}{File name (e.g. `capes_1987.parquet`).}
#'   \item{url}{Download URL of the file.}
#'   \item{bytes}{File size in bytes, used to check the download.}
#'   \item{md5}{MD5 checksum of the file.}
#' }
#' @source Derived from the CAPES open data portal,
#'   <https://dadosabertos.capes.gov.br/group/catalogo-de-teses-e-dissertacoes-brasil>.
#' @examples
#' data(capes_years)
#' head(capes_years)
#'
"capes_years"


#' Synthetic CAPES Data
#'
#' Aggregated data from the CAPES Catalog of Theses and Dissertations, 
#' containing summarized information by year, institution, area, program, type, region, and state (UF).
#'
#' @format A data frame with the following columns:
#' \describe{
#'   \item{base_year}{Reference year of the data.}
#'   \item{institution}{Higher Education Institution.}
#'   \item{area}{Area of Concentration.}
#'   \item{program_name}{Name of the Graduate Program.}
#'   \item{type}{Type of work (e.g., Master's, Doctorate).}
#'   \item{region}{Region of Brazil.}
#'   \item{state}{Federative Unit (state).}
#'   \item{n}{Total number of works.}
#' }
#' @source Synthetic data created from the CAPES Catalog of Theses and Dissertations.
#' @examples
#' data(capes_synthetic_df)
#' head(capes_synthetic_df)
#'
"capes_synthetic_df"


# Case-insensitive literal search of `terms` in the columns `fields` of `data`.
# Returns one logical per row: TRUE when any term (`match = "any"`) or every
# term (`match = "all"`) occurs in at least one of the fields. NA cells never
# match.
text_match <- function(data, terms, fields, match = c("any", "all")) {
  match <- match.arg(match)
  if (!is.character(terms) || length(terms) == 0 || anyNA(terms) || any(!nzchar(terms))) {
    stop("`term` must be a character vector with at least one non-empty string.")
  }
  if (!is.character(fields) || length(fields) == 0 || anyNA(fields)) {
    stop("`field` must be a character vector with at least one column name.")
  }
  missing_fields <- setdiff(fields, colnames(data))
  if (length(missing_fields) > 0) {
    stop("The following fields do not exist in the provided `data.frame`: ",
         paste0("'", missing_fields, "'", collapse = ", "))
  }
  hits <- vapply(terms, function(tm) {
    Reduce(`|`, lapply(fields, function(f) {
      x <- as.character(data[[f]])
      !is.na(x) & stringr::str_detect(x, stringr::fixed(tm, ignore_case = TRUE))
    }))
  }, logical(nrow(data)))
  hits <- matrix(hits, nrow = nrow(data))
  if (match == "all") rowSums(hits) == length(terms) else rowSums(hits) > 0
}

#' Read and filter data from the CAPES Catalog of Theses and Dissertations
#'
#' This function combines data from multiple Parquet files and applies optional filters, including text-based searches.
#'
#' @section Columns:
#' The yearly files have one row per thesis or dissertation and the columns
#' below (names in Portuguese, as in the CAPES source):
#' \describe{
#'   \item{ano_base}{Reference year.}
#'   \item{ies}{Higher education institution.}
#'   \item{area}{Evaluation area (*área de avaliação*).}
#'   \item{nome_programa}{Graduate program.}
#'   \item{tipo}{Type of work (e.g. master's dissertation, doctoral thesis).}
#'   \item{titulo, resumo}{Title and abstract.}
#'   \item{idioma}{Language of the work.}
#'   \item{autoria, orientacao}{Author and advisor.}
#'   \item{regiao, uf}{Region and state of the institution.}
#'   \item{grande_area, cd_grande_area}{Broad knowledge area (*grande área de
#'     conhecimento*): name and CAPES code.}
#'   \item{area_conhecimento, cd_area_conhecimento}{Knowledge area: name and code.}
#'   \item{subarea, cd_subarea}{Knowledge subarea: name and code (2013 onwards).}
#'   \item{especialidade, cd_especialidade}{Specialty: name and code (2013 onwards).}
#'   \item{area_concentracao}{Concentration area of the program (2013 onwards).}
#' }
#' The codes are stored as text. CAPES does not publish subarea, specialty and
#' concentration area for 1987-2012, so those columns are `NA` in these years.
#'
#' @param files A vector or list of paths to Parquet files.
#' @param filters A named list of filters. Values for the text columns `titulo` and
#'   `resumo` (or `title`/`abstract`) are matched as case-insensitive substrings,
#'   and a vector of terms keeps the rows containing any of them (e.g.,
#'   `list(titulo = c("varicela", "catapora"))`); all other columns are matched
#'   exactly (e.g., `list(ano_base = 1987, uf = "SP", titulo = "educação")`).
#' @return A `data.frame` containing the combined and filtered data.
#' @importFrom arrow open_dataset
#' @importFrom dplyr filter
#' @importFrom stringr str_detect fixed
#' @importFrom rlang sym
#' @importFrom magrittr %>%
#' @examples
#' \donttest{
#' # Download data for the years 1987 and 1990
#' capes_files <- download_capes_data(c(1987, 1990))
#' # Combine all selected data
#' combined_data <- read_capes_data(capes_files)
#' }
#' 
#' @export
read_capes_data <- function(files, filters = list()) {
  # Convert a named list into a vector of paths, if necessary
  if (is.list(files)) {
    files <- unlist(files, use.names = FALSE)
  }
  
  # Check if the files exist
  if (length(files) == 0) {
    stop("No files were provided (did the download fail?).")
  }
  if (any(!file.exists(files))) {
    stop("One or more specified files do not exist.")
  }
  
  # Open the Parquet files as a single dataset
  dataset <- arrow::open_dataset(files)
  
  # Get the column names of the dataset
  dataset_columns <- names(dataset)
  
  # Check if all filter fields exist in the dataset
  invalid_columns <- setdiff(names(filters), dataset_columns)
  if (length(invalid_columns) > 0) {
    stop("The following filter columns do not exist in the dataset: ", paste(invalid_columns, collapse = ", "))
  }
  
  # Columns searched as substrings instead of exact matches
  text_fields <- c("titulo", "resumo", "title", "abstract")

  # Apply exact filters
  if (length(filters) > 0) {
    for (field in names(filters)) {
      value <- filters[[field]]
      
      if (field %in% text_fields && is.character(value)) {
        # Text filter will be applied after reading
        next
      } else {
        # Filter for exact values
        dataset <- dataset %>%
          dplyr::filter(!!sym(field) %in% value)
      }
    }
  }
  
  # Load the filtered data into a `data.frame`
  data <- as.data.frame(dataset)
  
  # Apply text-based filters in memory
  for (field in intersect(names(filters), text_fields)) {
    term <- filters[[field]]
    if (is.null(term) || !is.character(term)) next
    data <- data[text_match(data, term, field), , drop = FALSE]
  }
  
  # Return the final data.frame
  return(data)
}

#' @rdname read_capes_data
#' @export
ler_dados_capes <- read_capes_data

#' Search for terms in text fields of the CAPES Catalog of Theses and Dissertations data
#'
#' Searches one or more terms in one or more text columns of a previously
#' loaded `data.frame`. Matching is literal (not a regular expression) and
#' case-insensitive.
#'
#' @param data A `data.frame` containing the CAPES Catalog of Theses and Dissertations data.
#' @param term A character vector with one or more terms to search for.
#' @param field A character vector with the name(s) of the column(s) to search in
#'   (e.g., `"titulo"`, `c("titulo", "resumo")`).
#' @param match How several terms combine: `"any"` (default) keeps rows where at
#'   least one term occurs in at least one field; `"all"` keeps rows where every
#'   term occurs (each in at least one of the fields).
#' @return A `data.frame` with the matching rows. When nothing matches, an empty
#'   `data.frame` with the same columns as `data` is returned with a message.
#' @importFrom stringr str_detect fixed
#' @examples
#' \donttest{
#' # Download data for the years 1987 and 1990
#' capes_files <- download_capes_data(c(1987, 1990))
#' # Combine all selected data
#' combined_data <- read_capes_data(capes_files)
#' # Titles mentioning "Educação"
#' results <- search_capes_text(combined_data, term = "Educação", field = "titulo")
#' # Titles or abstracts mentioning either synonym
#' results <- search_capes_text(
#'   combined_data,
#'   term = c("varicela", "catapora"),
#'   field = c("titulo", "resumo")
#' )
#' # Abstracts mentioning both terms
#' results <- search_capes_text(
#'   combined_data,
#'   term = c("saúde", "escola"),
#'   field = "resumo",
#'   match = "all"
#' )
#' }
#' @export
search_capes_text <- function(data, term, field, match = c("any", "all")) {
  # Validate input
  if (missing(data) || missing(term) || missing(field)) {
    stop("The parameters `data`, `term`, and `field` are required.")
  }

  if (!is.data.frame(data)) {
    stop("The `data` parameter must be a `data.frame`.")
  }

  # Keep the rows where the terms occur in the fields
  results <- data[text_match(data, term, field, match), , drop = FALSE]

  # Check if there are results
  if (nrow(results) == 0) {
    message("No results found for the search.")
  }

  results
}


#' @rdname search_capes_text
#' @export
buscar_texto_capes <- search_capes_text

#' Download CAPES Data
#'
#' Downloads the yearly Parquet files of the CAPES Catalog of Theses and
#' Dissertations for the selected years. The file list and download URLs come
#' from [capes_years].
#'
#' A file already present in `destination` is reused only when its size matches
#' the one recorded in [capes_years]; otherwise (for instance, a file downloaded
#' with an earlier version of the package, which had fewer columns) it is
#' downloaded again.
#'
#' @param years A vector with the desired years (1987-2024).
#' @param destination The directory where the files will be saved (default: temporary directory).
#' @param timeout The timeout in seconds for the download process (default: 120 seconds).
#' @param base_url Optional base URL of a mirror hosting the files listed in
#'   [capes_years]. Defaults to `getOption("capesR.base_url")`; when `NULL`,
#'   the `url` column of [capes_years] is used.
#' @return A named list (by year) of file paths for the downloaded or already existing files.
#' @importFrom utils download.file
#' @importFrom utils data
#' @examples
#' \donttest{
#' # Download data for the years 1987 and 1990
#' capes_files <- download_capes_data(c(1987, 1990))
#' }
#' @export
download_capes_data <- function(years, destination = tempdir(), timeout = 120,
                                base_url = getOption("capesR.base_url")) {

  # Save the current timeout and restore it on exit
  original_timeout <- getOption("timeout")
  on.exit(options(timeout = original_timeout), add = TRUE)

  # Set the new timeout
  options(timeout = timeout)

  # Check if destination directory exists, if not, try to create it
  if (!dir.exists(destination)) {
    message("The directory does not exist. Attempting to create: ", destination)
    success <- dir.create(destination, recursive = TRUE)

    if (!success) {
      stop("Failed to create the directory: ", destination)
    } else {
      message("Directory successfully created: ", destination)
    }
  }

  # Load the file index
  data("capes_years", package = "capesR", envir = environment())
  index <- capesR::capes_years

  # Filter files for the selected years
  selected <- index[index$year %in% years, ]

  # Check for invalid years
  if (nrow(selected) == 0) {
    stop("None of the selected years are available. Available years: ",
         min(index$year), "-", max(index$year), ".")
  }
  unavailable <- setdiff(years, selected$year)
  if (length(unavailable) > 0) {
    warning("Years not available and skipped: ", paste(unavailable, collapse = ", "))
  }

  # Loop to download files
  downloaded_files <- list()
  for (i in seq_len(nrow(selected))) {
    year <- as.character(selected$year[i])
    file_destination <- file.path(destination, selected$file[i])

    # Reuse an existing file only if it is the current version of the data
    if (file.exists(file_destination)) {
      if (is.na(selected$bytes[i]) || file.size(file_destination) == selected$bytes[i]) {
        message("File already exists: ", file_destination)
        downloaded_files[[year]] <- file_destination
        next
      }
      message("Existing file for year ", year, " differs from the current data ",
              "(older version or incomplete); downloading it again.")
    }

    url <- if (is.null(base_url)) {
      selected$url[i]
    } else {
      paste0(sub("/+$", "", base_url), "/", selected$file[i])
    }
    message("Downloading: ", file_destination)

    # Download to a temporary file so an interrupted download is not mistaken
    # for a complete one on the next call
    part <- paste0(file_destination, ".part")
    result <- tryCatch(
      {
        download.file(url, part, mode = "wb")
        TRUE
      },
      error = function(e) {
        message("Failed to download file for year ", year, ": ", conditionMessage(e))
        FALSE
      }
    )

    if (!result) {
      unlink(part)
      next
    }

    if (!is.na(selected$bytes[i]) && file.size(part) != selected$bytes[i]) {
      unlink(part)
      message("Download for year ", year, " has unexpected size; file discarded.")
      next
    }

    # file.rename() does not overwrite on Windows
    unlink(file_destination)
    file.rename(part, file_destination)
    downloaded_files[[year]] <- file_destination
  }

  # Return the list of file paths
  return(downloaded_files)
}

#' @rdname download_capes_data
#' @export
baixar_dados_capes <- download_capes_data
