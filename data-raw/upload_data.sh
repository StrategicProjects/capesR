#!/bin/zsh
# Uploads dados_parquet_v2/*.parquet (21 columns, capesR >= 0.3.0) to the data
# host used by capesR, in the v2/ folder. The files at the repository root are
# the 12-column ones that capesR 0.2.x checks by size: never replace them.
# Afterwards run data-raw/capes_years.R.
# Needs HF_TOKEN:  export HF_TOKEN="$(sed -n 's/^TOKEN_HF=//p' .env)"
set -euo pipefail
cd "$(dirname "$0")/.."
ls dados_parquet_v2/capes_*.parquet | wc -l | grep -q '^ *38$' || { echo "expected 38 files in dados_parquet_v2/"; exit 1; }

### Option A — Hugging Face Datasets (in use) -------------------------------
REPO="mlkwy/capesR"
hf upload "$REPO" dados_parquet_v2 v2 --repo-type dataset --include "*.parquet" \
  --commit-message "CAPES catalog 1987-2024 (parquet, v2)"
hf upload "$REPO" data-raw/README_dataset.md README.md --repo-type dataset
# Files are then served at:
#   https://huggingface.co/datasets/$REPO/resolve/main/v2/capes_1987.parquet

### Option B — GitHub Release on mlkwy/capesR ------------------------------
# TAG="data-v1"
# gh release create "$TAG" --repo mlkwy/capesR --title "CAPES data $TAG" \
#   --notes "Yearly parquet files of the CAPES catalog (1987-2024)." dados_parquet/capes_*.parquet
# base_url would be: https://github.com/mlkwy/capesR/releases/download/$TAG
