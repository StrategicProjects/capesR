## R CMD check results

0 errors ✔ | 0 warnings ✔ | 0 notes ✔

Checked locally on macOS (R 4.6.0), including the \donttest{} examples that
download data.

## Changes in this release (0.3.0)

* The yearly data files gain nine columns with the CAPES knowledge-area
  classification (names and codes), requested by users. The 12 existing
  columns keep their names and position; `area` now has the same meaning
  (evaluation area) in every year, which is described in NEWS as a breaking
  change in the data for 1987-2012.
* The files were rebuilt from the XLSX files of the CAPES open data portal and
  are served from a new folder of the same data repository, so earlier
  versions of the package keep working with the files they expect.
* `download_capes_data()` downloads a file again when the copy found in
  `destination` does not have the expected size (e.g. a file saved by an
  earlier version of the package).
* Examples that download data remain in \donttest{} and write only to
  `tempdir()`.
