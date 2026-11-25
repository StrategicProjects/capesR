#!/bin/bash
# Runs the whole data refresh on a server, independent of the local session:
#   1. downloads the CAPES XLSX files of the requested years (sequential; the
#      CAPES server allows one connection and has no byte ranges),
#   2. converts them with build_parquet.R (output in dados_parquet_v2/),
#   3. writes dados_parquet_v2/checksums.csv (year, bytes, md5),
#   4. optionally uploads the parquets to Hugging Face, folder v2/ (only if
#      HF_TOKEN is set; otherwise copy dados_parquet_v2/ back and run
#      data-raw/upload_data.sh locally).
# Needs next to it: build_parquet.R, download_xlsx.sh and urls_xlsx.tsv
# (year<TAB>url of the XLSX resource; update the URL when CAPES adds or
# revises a year -- see data-raw/capes_resources.json / the CKAN API).
# Usage on the server:  YEARS='2025' nohup ./etl_remote.sh > logs/etl.log 2>&1 < /dev/null &
# Progress markers: "STEP ...", "ok <file>", "FAIL <file>", "ETL_DONE" / "ETL_FAILED".
set -u
cd "$(dirname "$0")"
export R_LIBS_USER="$HOME/R/x86_64-pc-linux-gnu-library/4.5"
export CAPES_PARQUET_DIR=dados_parquet_v2
YEARS="${YEARS:?set YEARS, e.g. YEARS='2025'}"

echo "STEP download $(date -u +%FT%TZ)"
for y in $YEARS; do
  grep -q "^$y	" urls_xlsx.tsv || { echo "FAIL no URL for $y in urls_xlsx.tsv"; echo ETL_FAILED; exit 1; }
  # a revised file must replace the previous download
  rm -f "dados_xlsx/capes_$y.xlsx"
done
YEARS_RE="^($(echo $YEARS | tr ' ' '|'))	"
grep -E "$YEARS_RE" urls_xlsx.tsv > urls_xlsx.selected.tsv
URLS=urls_xlsx.selected.tsv ./download_xlsx.sh | tee logs/download_xlsx.last.log
grep -q DOWNLOAD_XLSX_DONE logs/download_xlsx.last.log || { echo ETL_FAILED; exit 1; }

echo "STEP parquet $(date -u +%FT%TZ)"
Rscript build_parquet.R $YEARS || { echo ETL_FAILED; exit 1; }
for y in $YEARS; do echo "ok $CAPES_PARQUET_DIR/capes_$y.parquet $(stat -c %s $CAPES_PARQUET_DIR/capes_$y.parquet)"; done

echo "STEP checksums $(date -u +%FT%TZ)"
( echo "year,bytes,md5"; for y in $YEARS; do p="$CAPES_PARQUET_DIR/capes_$y.parquet"; echo "$y,$(stat -c %s "$p"),$(md5sum "$p" | cut -d' ' -f1)"; done ) > $CAPES_PARQUET_DIR/checksums.csv
cat $CAPES_PARQUET_DIR/checksums.csv

if [ -z "${HF_TOKEN:-}" ]; then echo "skip upload (no HF_TOKEN)"; echo ETL_DONE; exit 0; fi
echo "STEP upload $(date -u +%FT%TZ)"
HF=${HF:-$HOME/capesR-etl/venv/bin/hf}
inc=(); for y in $YEARS; do inc+=(--include "capes_$y.parquet"); done
for try in 1 2 3; do
  "$HF" upload mlkwy/capesR $CAPES_PARQUET_DIR v2 --repo-type dataset "${inc[@]}" \
     --commit-message "Refresh $(echo $YEARS | tr ' ' ',') from CAPES portal ($(date -u +%F))" && { echo "ok upload"; echo ETL_DONE; exit 0; }
  echo "retry $try upload"; sleep 60
done
echo "FAIL upload"; echo ETL_FAILED; exit 1
