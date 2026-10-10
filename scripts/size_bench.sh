#!/usr/bin/env bash
# Measure Monero proof SIZES (bytes) via the size_probe binary, tag by ref+commit,
# and push to the Pushgateway. Sizes are deterministic (host-independent).
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IMAGE="${SIZE_IMAGE:-monero-ringct-size:latest}"
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
OUT="$HERE/results/size_${STAMP}"
mkdir -p "$OUT"

BIN="$(docker run --rm "$IMAGE" bash -lc \
  'find /monero/build -type f -name size_probe -perm -u+x | head -1')"
[[ -z "$BIN" ]] && { echo "ERROR: size_probe not found in $IMAGE"; exit 1; }

docker run --rm "$IMAGE" cat /monero_commit.txt > "$OUT/monero_commit.txt" 2>/dev/null || echo unknown > "$OUT/monero_commit.txt"
REF="$(docker run --rm "$IMAGE" bash -lc 'cat /monero_ref.txt 2>/dev/null' || true)"
REF="${REF:-${MONERO_REF:-unknown}}"
{
  echo "timestamp_utc=$STAMP"
  echo "monero_commit=$(cat "$OUT/monero_commit.txt")"
  echo "monero_ref=$REF"
  echo "image=$IMAGE"
} > "$OUT/meta.env"

echo "[*] running size_probe ($BIN)"
docker run --rm "$IMAGE" "$BIN" | tee "$OUT/raw.txt"

# Convert to Prometheus metrics: monero_proof_size_bytes{scheme,param}.
awk '
  /^bulletproof_plus outputs=/ {split($2,a,"=");split($3,b,"=");
    printf "monero_proof_size_bytes{scheme=\"bulletproof_plus\",param=\"%s\"} %s\n",a[2],b[2]}
  /^bulletproof outputs=/ {split($2,a,"=");split($3,b,"=");
    printf "monero_proof_size_bytes{scheme=\"bulletproof\",param=\"%s\"} %s\n",a[2],b[2]}
  /^clsag ring=/ {split($2,a,"=");split($3,b,"=");
    printf "monero_proof_size_bytes{scheme=\"clsag\",param=\"%s\"} %s\n",a[2],b[2]}
' "$OUT/raw.txt" > "$OUT/metrics.prom"
{ echo "# HELP monero_proof_size_bytes serialized proof size (bytes)."
  echo "# TYPE monero_proof_size_bytes gauge"; cat "$OUT/metrics.prom"; } > "$OUT/metrics.prom.tmp"
mv "$OUT/metrics.prom.tmp" "$OUT/metrics.prom"

echo "[*] metrics:"; grep '^monero_proof_size_bytes' "$OUT/metrics.prom"

if [[ "${PUSH:-1}" == "1" ]]; then
  "$HERE/scripts/push_metrics.sh" "$OUT/metrics.prom" || echo "[i] push skipped (stack down)"
fi
echo "[*] done: $OUT"
