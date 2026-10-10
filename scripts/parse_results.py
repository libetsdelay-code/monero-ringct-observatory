#!/usr/bin/env python3
"""Parse Monero performance_tests output into structured JSON + a Prometheus
textfile.

Real line format (confirmed 2026-10-10):
  <name> (<N> calls) - OK: <mean> <unit>/call (min <m> <u>, 90th <p> <u>, \
median <md> <u>, std dev <s> <u>)
units: µs | ms | s

Usage: parse_results.py results/run_<stamp>/raw.txt
"""
import json, re, sys, pathlib

RAW = pathlib.Path(sys.argv[1])
OUTDIR = RAW.parent

U = {"µs": 1.0, "us": 1.0, "ms": 1_000.0, "s": 1_000_000.0}

LINE = re.compile(
    r"^(?P<name>.+?)\s*\((?P<calls>\d+)\s*calls?\)\s*-\s*OK:\s*"
    r"(?P<mean>[\d.]+)\s*(?P<mu>µs|us|ms|s)/call\s*\("
    r"min\s*(?P<min>[\d.]+)\s*(?P<minu>µs|us|ms|s),\s*"
    r"90th\s*(?P<p90>[\d.]+)\s*(?P<p90u>µs|us|ms|s),\s*"
    r"median\s*(?P<median>[\d.]+)\s*(?P<medu>µs|us|ms|s),\s*"
    r"std dev\s*(?P<std>[\d.]+)\s*(?P<stdu>µs|us|ms|s)\)"
)

def us(v, u):
    return round(float(v) * U[u], 3)

def classify(name):
    n = name.lower()
    if "clsag" in n:
        return "clsag"
    if "aggregated_bulletproofs" in n:
        return "bulletproof_batch_verify"
    if "check_tx_signature" in n:
        return "tx_verify"
    if "construct_tx" in n:
        return "tx_construct"
    if "bulletproof" in n:
        return "bulletproof"
    return "other"

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
    rows, unmatched = [], 0
    for ln in RAW.read_text(errors="replace").splitlines():
        ln = ln.strip()
        if not ln:
            continue
        mt = LINE.match(ln)
        if not mt:
            unmatched += 1
            continue
        g = mt.groupdict()
        rows.append({
            "name": g["name"].strip(),
            "category": classify(g["name"]),
            "calls": int(g["calls"]),
            "mean_us": us(g["mean"], g["mu"]),
            "median_us": us(g["median"], g["medu"]),
            "min_us": us(g["min"], g["minu"]),
            "p90_us": us(g["p90"], g["p90u"]),
            "std_us": us(g["std"], g["stdu"]),
        })

    result = {"meta": meta, "measurements": rows,
              "count": len(rows), "unmatched_lines": unmatched}
    (OUTDIR / "parsed.json").write_text(json.dumps(result, indent=2))

    # ref/commit are attached as Pushgateway grouping labels (see push_metrics.sh),
    # so they are intentionally NOT in the metric lines here.
    out = ["# HELP monero_bench_median_us performance_tests median time (us).",
           "# TYPE monero_bench_median_us gauge"]
    for r in rows:
        safe = re.sub(r"[^a-zA-Z0-9_]", "_", r["name"])
        out.append(
            f'monero_bench_median_us{{test="{safe}",category="{r["category"]}"}} '
            f'{r["median_us"]}'
        )
    (OUTDIR / "metrics.prom").write_text("\n".join(out) + "\n")

    # Console summary grouped by category.
    print(f"[*] parsed {len(rows)} measurements ({unmatched} lines ignored)")
    for cat in ("clsag", "bulletproof_batch_verify", "tx_verify",
                "tx_construct", "bulletproof", "other"):
        sub = [r for r in rows if r["category"] == cat]
        if sub:
            print(f"\n== {cat} ==")
            for r in sub:
                print(f"  {r['median_us']:>12.1f} us (median)  {r['name']}")
    print(f"\n[*] wrote {OUTDIR/'parsed.json'} and {OUTDIR/'metrics.prom'}")

if __name__ == "__main__":
    main()
