## R CMD check results

0 errors ✔ | 0 warnings ✔ | 0 notes ✔

Checked locally on macOS (R 4.6.0), including the \donttest{} examples that
download data.

## Changes in this release (0.2.1)

* URL and BugReports moved to <https://github.com/StrategicProjects/capesR>.
  The repository used in 0.2.0 (<https://github.com/milkway/capesR>) was a
  temporary home kept online as a pointer to the new one; the new repository
  also holds the full history of the original hugoavmedeiros/capesR
  repository.
* `search_capes_text()` accepts several terms and several fields; the new
  `match = "all"` argument requires every term instead of any. The
  `read_capes_data()` text filters (`titulo`, `resumo`) also accept a vector
  of terms.
* When nothing matches, `search_capes_text()` returns an empty `data.frame`
  with the same columns as the input.
* Added unit tests (testthat, in Suggests).
* Added ORCID identifiers for the authors.
