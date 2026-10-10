#!/usr/bin/env bash
# Push a run's metrics.prom to the Pushgateway, grouped by Monero ref + commit
# so every version is a distinct, persistent group (enables cross-version trends).
# Usage: push_metrics.sh results/run_<stamp>/metrics.prom
set -euo pipefail
PROM="${1:?usage: push_metrics.sh <metrics.prom>}"
PUSHGW="${PUSHGW:-http://localhost:9091}"
DIR="$(dirname "$PROM")"

# Read ref + commit from the run's meta.env.
monero_ref="unknown"; monero_commit="unknown"
if [[ -f "$DIR/meta.env" ]]; then
  # shellcheck disable=SC1090
  source <(grep -E '^(monero_commit|monero_ref)=' "$DIR/meta.env")
fi
safe_ref="$(echo "${monero_ref}" | tr '/ :' '___')"
short_commit="${monero_commit:0:12}"

if ! curl -sf -o /dev/null "$PUSHGW/-/healthy" 2>/dev/null; then
  echo "[!] pushgateway not reachable at $PUSHGW (is the stack up?)" >&2
  exit 1
fi

# Grouping labels go in the URL path; honor_labels=true in Prometheus keeps them.
curl -sf --data-binary @"$PROM" \
  "$PUSHGW/metrics/job/ringct_bench/ref/${safe_ref}/commit/${short_commit}"
echo "[*] pushed $PROM (ref=${safe_ref} commit=${short_commit}) -> $PUSHGW"
