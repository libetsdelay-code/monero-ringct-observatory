#!/usr/bin/env bash
# Nightly observatory run: benchmark each configured Monero ref and push results.
# Rebuilds images (Docker layer cache makes unchanged refs fast; a moved branch
# tip re-clones and recompiles). Intended to run from cron / systemd timer.
#
# Config: REFS env (space-separated) or the default list below.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$HERE"

REFS="${REFS:-release-v0.18}"
LOG="$HERE/results/nightly_$(date -u +%Y%m%dT%H%M%SZ).log"

echo "[nightly] $(date -u +%FT%TZ) refs: $REFS" | tee -a "$LOG"

# Ensure the observability stack is up (idempotent).
docker compose -f "$HERE/observability/docker-compose.yml" up -d >>"$LOG" 2>&1 || true

for ref in $REFS; do
  echo "[nightly] benchmarking $ref" | tee -a "$LOG"
  # --no-cache on the clone layer would force a fresh pull; we rely on bench_ref
  # rebuilding, which re-clones the (possibly moved) ref.
  if "$HERE/scripts/bench_ref.sh" "$ref" >>"$LOG" 2>&1; then
    echo "[nightly] OK $ref" | tee -a "$LOG"
  else
    echo "[nightly] FAILED $ref (see $LOG)" | tee -a "$LOG"
  fi
done
echo "[nightly] done -> $LOG"
