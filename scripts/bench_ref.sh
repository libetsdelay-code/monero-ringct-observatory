#!/usr/bin/env bash
# Build Monero's performance_tests for a specific ref (branch/tag/commit) and
# benchmark it. Results are tagged with that ref + its exact commit, so the
# dashboard can compare versions.
#
# Usage: bench_ref.sh <monero-ref> [filter-regex]
#   bench_ref.sh release-v0.18
#   bench_ref.sh master '.*[Cc]lsag.*'
#   bench_ref.sh v0.18.3.4
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REF="${1:?usage: bench_ref.sh <monero-ref> [filter]}"
FILTER="${2:-.*[Cc]lsag.*|.*[Bb]ulletproof.*}"
BUILD_JOBS="${BUILD_JOBS:-4}"

safe_ref="$(echo "$REF" | tr '/ :' '___')"
IMAGE="monero-ringct-bench:${safe_ref}"

echo "[*] ref:   $REF"
echo "[*] image: $IMAGE"
echo "[*] building (reuses cache if already built)..."
docker build \
  --build-arg MONERO_REF="$REF" \
  --build-arg BUILD_JOBS="$BUILD_JOBS" \
  -f "$HERE/docker/Dockerfile.bench" -t "$IMAGE" "$HERE"

echo "[*] running benchmark..."
IMAGE="$IMAGE" MONERO_REF="$REF" FILTER="$FILTER" "$HERE/scripts/run_bench.sh"
