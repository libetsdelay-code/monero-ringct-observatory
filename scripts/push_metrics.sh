#!/usr/bin/env bash
# Push a run's metrics.prom to the Pushgateway.
# Usage: push_metrics.sh results/run_<stamp>/metrics.prom
set -euo pipefail
PROM="${1:?usage: push_metrics.sh <metrics.prom>}"
PUSHGW="${PUSHGW:-http://localhost:9091}"

if ! curl -sf -o /dev/null "$PUSHGW/-/healthy" 2>/dev/null; then
  echo "[!] pushgateway not reachable at $PUSHGW (is the stack up?)" >&2
  exit 1
fi
curl -sf --data-binary @"$PROM" "$PUSHGW/metrics/job/ringct_bench"
echo "[*] pushed $PROM -> $PUSHGW (job=ringct_bench)"
