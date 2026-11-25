#!/bin/bash
# Downloads the CAPES XLSX files listed in urls_xlsx.tsv (year<TAB>url; another
# list can be given in the URLS env var) into
# dados_xlsx/capes_<year>.xlsx, one at a time (the CAPES server allows a single
# connection and has no byte ranges, so every attempt restarts from zero).
# Markers: "ok <file> <bytes>", "retry", "FAIL <file>", "DOWNLOAD_XLSX_DONE".
set -u
cd "$(dirname "$0")"
mkdir -p dados_xlsx
fail=0
while IFS=$'\t' read -r y url; do
  f="dados_xlsx/capes_$y.xlsx"
  [ -s "$f" ] && { echo "skip $f"; continue; }
  for try in 1 2 3 4 5 6; do
    rm -f "$f.part"
    # a valid xlsx is a zip: test it before accepting the download
    curl -sSL --retry 3 --max-time 7200 "$url" -o "$f.part" && unzip -tq "$f.part" > /dev/null 2>&1 && { mv "$f.part" "$f"; echo "ok $f $(stat -c %s "$f")"; break; }
    echo "retry $try $f"; sleep 60
  done
  [ -s "$f" ] || { echo "FAIL $f"; fail=1; }
done < "${URLS:-urls_xlsx.tsv}"
[ "$fail" = 0 ] && echo DOWNLOAD_XLSX_DONE || echo DOWNLOAD_XLSX_FAILED
