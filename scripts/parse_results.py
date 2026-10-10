#!/usr/bin/env python3
"""Parse Monero performance_tests output into structured JSON + a Prometheus
textfile. The exact line format is confirmed against the first real run, then
this parser is tightened. For now it is tolerant and keeps anything it finds.

Usage: parse_results.py results/run_<stamp>/raw.txt
"""
import json, re, sys, os, pathlib

RAW = pathlib.Path(sys.argv[1])
OUTDIR = RAW.parent

# performance_tests prints one line per test, e.g.:
#   test_name (1000 runs): 123.4 microseconds per call, min 120 max 130
# The regex is deliberately broad; refine after seeing real output.
LINE = re.compile(
    r"^(?P<name>[A-Za-z0-9_:<>,\s\.\-\(\)]+?)\s*"
    r"(?:\((?P<runs>\d+)\s*runs?\))?\s*[:\-]\s*"
    r"(?P<value>[\d\.]+)\s*(?P<unit>ns|us|microseconds|ms|milliseconds|s)\b",
    re.IGNORECASE,
)

UNIT_TO_US = {"ns": 1e-3, "us": 1.0, "microseconds": 1.0,
              "ms": 1e3, "milliseconds": 1e3, "s": 1e6}

def load_meta(d):
    m = {}
    p = d / "meta.env"
    if p.exists():
        for ln in p.read_text().splitlines():
            if "=" in ln:
                k, v = ln.split("=", 1)
                m[k] = v
    return m

def main():
    meta = load_meta(OUTDIR)
    rows = []
    for ln in RAW.read_text(errors="replace").splitlines():
        mt = LINE.match(ln.strip())
        if not mt:
            continue
        unit = mt.group("unit").lower()
        val = float(mt.group("value"))
        rows.append({
            "name": mt.group("name").strip(),
            "runs": int(mt.group("runs")) if mt.group("runs") else None,
            "value_us": round(val * UNIT_TO_US.get(unit, 1.0), 4),
            "raw_value": val,
            "raw_unit": unit,
        })

    result = {"meta": meta, "measurements": rows, "count": len(rows)}
    (OUTDIR / "parsed.json").write_text(json.dumps(result, indent=2))

    # Prometheus textfile exporter format.
    commit = meta.get("monero_commit", "unknown")[:12]
    lines = [
        "# HELP monero_bench_us Monero performance_tests timing (microseconds).",
        "# TYPE monero_bench_us gauge",
    ]
    for r in rows:
        safe = re.sub(r"[^a-zA-Z0-9_]", "_", r["name"])
        lines.append(
            f'monero_bench_us{{test="{safe}",commit="{commit}"}} {r["value_us"]}'
        )
    (OUTDIR / "metrics.prom").write_text("\n".join(lines) + "\n")

    print(f"[*] parsed {len(rows)} measurements")
    print(f"[*] wrote  {OUTDIR/'parsed.json'}")
    print(f"[*] wrote  {OUTDIR/'metrics.prom'}")
    if not rows:
        print("[!] 0 parsed — inspect raw.txt and tighten the LINE regex.")

if __name__ == "__main__":
    main()
