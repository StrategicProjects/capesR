skip_if_not_installed("arrow")

df <- data.frame(
  ano_base = c(2020L, 2020L, 2021L),
  uf = c("SP", "PE", "PE"),
  titulo = c("Varicela em crianças", "A catapora no Brasil", "Educação"),
  resumo = c("a", "b", NA),
  stringsAsFactors = FALSE
)
f <- tempfile(fileext = ".parquet")
arrow::write_parquet(df, f)

test_that("exact and text filters combine", {
  res <- read_capes_data(f, filters = list(uf = "PE", titulo = "catapora"))
  expect_equal(res$ano_base, 2020L)
})

test_that("text filters accept a vector of terms", {
  res <- read_capes_data(f, filters = list(titulo = c("varicela", "catapora")))
  expect_equal(res$ano_base, c(2020L, 2020L))
})

test_that("NA in the text column never matches", {
  res <- read_capes_data(f, filters = list(resumo = "a"))
  expect_equal(nrow(res), 1L)
})

test_that("unknown filter columns are rejected", {
  expect_error(read_capes_data(f, filters = list(foo = 1)), "foo")
})

test_that("an outdated local file is not reused by download_capes_data()", {
  dest <- tempfile("capes")
  dir.create(dest)
  stale <- file.path(dest, "capes_1987.parquet")
  writeLines("not the current file", stale)
  # an unreachable mirror: the download fails, and the stale file must not be returned
  mirror <- paste0("file://", tempfile("no-such-mirror"))
  msgs <- character()
  res <- suppressWarnings(withCallingHandlers(
    download_capes_data(1987, destination = dest, base_url = mirror),
    message = function(m) {
      msgs <<- c(msgs, conditionMessage(m))
      invokeRestart("muffleMessage")
    }
  ))
  expect_true(any(grepl("differs from the current data", msgs)))
  expect_length(res, 0)
})
