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
{
  echo "timestamp_utc=$STAMP"
  echo "monero_commit=$(cat "$OUT/monero_commit.txt")"
  echo "image=$IMAGE"
  echo "host_cpu=$(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2 | sed 's/^ //')"
  echo "host_kernel=$(uname -r)"
  echo "filter=$FILTER"
} > "$OUT/meta.env"

# Run the benchmark. --filter selects tests by name; --stats prints distribution.
docker run --rm "$IMAGE" bash -lc \
  "$BIN --filter '$FILTER' --stats" 2>&1 | tee "$OUT/raw.txt"

echo "[*] done. Raw output in $OUT/raw.txt"
echo "[*] next: python3 scripts/parse_results.py $OUT/raw.txt"
