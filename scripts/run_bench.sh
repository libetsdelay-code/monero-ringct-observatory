#!/usr/bin/env bash
# Run Monero's performance_tests for the RingCT crypto we care about,
# capture raw output + metadata into results/.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IMAGE="${IMAGE:-monero-ringct-bench:latest}"
# Regex over test names. CLSAG + Bulletproofs(+) verification/proving.
FILTER="${FILTER:-.*[Cc]lsag.*|.*[Bb]ulletproof.*}"
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
OUT="$HERE/results/run_${STAMP}"
mkdir -p "$OUT"

echo "[*] image:  $IMAGE"
echo "[*] filter: $FILTER"
echo "[*] out:    $OUT"

# Locate the performance_tests binary inside the image (path varies by version).
BIN="$(docker run --rm "$IMAGE" bash -lc \
  'find /monero/build -type f -name performance_tests -perm -u+x | head -1')"
if [[ -z "$BIN" ]]; then echo "ERROR: performance_tests binary not found in image"; exit 1; fi
echo "[*] binary: $BIN"

# Metadata: exact monero commit, host CPU, image.
docker run --rm "$IMAGE" cat /monero_commit.txt > "$OUT/monero_commit.txt"
# Monero ref: prefer /monero_ref.txt baked into the image, else env, else unknown.
REF="$(docker run --rm "$IMAGE" bash -lc 'cat /monero_ref.txt 2>/dev/null' || true)"
REF="${REF:-${MONERO_REF:-unknown}}"
{
  echo "timestamp_utc=$STAMP"
  echo "monero_commit=$(cat "$OUT/monero_commit.txt")"
  echo "monero_ref=$REF"
  echo "image=$IMAGE"
  echo "host_cpu=$(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2 | sed 's/^ //')"
  echo "host_kernel=$(uname -r)"
  echo "filter=$FILTER"
} > "$OUT/meta.env"

# Run the benchmark. --filter selects tests by name; --stats prints distribution.
docker run --rm "$IMAGE" bash -lc \
  "$BIN --filter '$FILTER' --stats" 2>&1 | tee "$OUT/raw.txt"

echo "[*] raw output in $OUT/raw.txt"

# Parse into JSON + Prometheus textfile.
python3 "$HERE/scripts/parse_results.py" "$OUT/raw.txt" || echo "[!] parse failed"

# Push to Pushgateway if the stack is up (non-fatal).
if [[ "${PUSH:-1}" == "1" && -f "$OUT/metrics.prom" ]]; then
  "$HERE/scripts/push_metrics.sh" "$OUT/metrics.prom" || echo "[i] skipped push (stack not up)"
fi

echo "[*] done: $OUT"
