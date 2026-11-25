#!/usr/bin/env python3
"""Compare the CSV files published by CAPES (Catálogo de Teses e Dissertações)
with the snapshot in data-raw/capes_resources.json.

  python3 data-raw/check_capes_updates.py            # print diff, exit 1 if any
  python3 data-raw/check_capes_updates.py --update   # rewrite the snapshot

Exit codes: 0 = no changes, 1 = changes found, 2 = the portal could not be
queried (network error), so the caller must not treat it as "changes".

Only the standard library is used so it runs unchanged in GitHub Actions.
"""
import http.client, json, sys, time, urllib.request
from pathlib import Path

API = ("https://dadosabertos.capes.gov.br/api/3/action/package_search"
       "?fq=groups:catalogo-de-teses-e-dissertacoes-brasil&rows=100")
SNAPSHOT = Path(__file__).with_name("capes_resources.json")


def fetch_json(attempts=4, wait=30):
    """Query CKAN, retrying: the CAPES server often drops connections."""
    req = urllib.request.Request(API, headers={"User-Agent": "capesR-update-check"})
    for i in range(1, attempts + 1):
        try:
            with urllib.request.urlopen(req, timeout=120) as r:
                data = json.load(r)
            if data.get("success"):
                return data
            err = "CKAN answered success=false"
        except (OSError, http.client.HTTPException, ValueError) as e:
            err = f"{type(e).__name__}: {e}"
        print(f"attempt {i}/{attempts} failed: {err}", file=sys.stderr)
        if i < attempts:
            time.sleep(wait * i)
    # Exit code 2 = could not check; 1 is reserved for "there are changes".
    print("could not reach the CAPES portal", file=sys.stderr)
    sys.exit(2)


def fetch():
    data = fetch_json()
    out = {}
    for pkg in data["result"]["results"]:
        for res in pkg["resources"]:
            if (res.get("format") or "").upper() != "CSV":
                continue
            out[res["id"]] = {
                "dataset": pkg["name"],
                "name": res.get("name"),
                "last_modified": (res.get("last_modified") or res.get("created") or "")[:10],
                "size": res.get("size"),
                "url": res.get("url"),
            }
    return dict(sorted(out.items(), key=lambda kv: kv[1]["name"] or ""))


def diff(old, new):
    lines = []
    for rid, r in new.items():
        if rid not in old:
            lines.append(f"- **novo**: `{r['name']}` ({r['dataset']}, {r['last_modified']}) {r['url']}")
        elif (old[rid]["last_modified"], old[rid]["size"]) != (r["last_modified"], r["size"]):
            lines.append(f"- **revisado**: `{r['name']}` ({old[rid]['last_modified']} -> {r['last_modified']}) {r['url']}")
    for rid, r in old.items():
        if rid not in new:
            lines.append(f"- **removido**: `{r['name']}`")
    return lines


def main():
    new = fetch()
    if "--update" in sys.argv:
        SNAPSHOT.write_text(json.dumps(new, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
        print(f"snapshot written: {len(new)} CSV resources")
        return
    old = json.loads(SNAPSHOT.read_text(encoding="utf-8")) if SNAPSHOT.exists() else {}
    lines = diff(old, new)
    if not lines:
        print("no changes")
        return
    print("\n".join(lines))
    sys.exit(1)


if __name__ == "__main__":
    main()
