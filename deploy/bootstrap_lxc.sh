#!/usr/bin/env bash
# One-shot bootstrap to run INSIDE the server LXC.
# Installs Docker if missing, brings up the observability stack, builds the
# benchmark image, and runs the first benchmark + size probe.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$HERE"

echo "== [1/5] Docker =="
if ! command -v docker >/dev/null 2>&1; then
  echo "  installing docker..."
  curl -fsSL https://get.docker.com | sh
fi
docker info >/dev/null 2>&1 || { echo "  ERROR: docker daemon not usable (LXC needs nesting=1)"; exit 1; }

echo "== [2/5] observability stack =="
if [ ! -f observability/.env ]; then
  cp observability/.env.example observability/.env
  echo "  NOTE: created observability/.env from the example; set the real exporter IPs."
fi
docker compose -f observability/docker-compose.yml up -d

echo "== [3/5] build benchmark image (compiles Monero performance_tests; slow) =="
docker build --build-arg MONERO_REF=release-v0.18 --build-arg BUILD_JOBS="$(nproc)" \
  -f docker/Dockerfile.bench -t monero-ringct-bench:release-v0_18 .
docker tag monero-ringct-bench:release-v0_18 monero-ringct-bench:latest

echo "== [4/5] timing benchmark =="
IMAGE=monero-ringct-bench:release-v0_18 MONERO_REF=release-v0.18 ./scripts/run_bench.sh

echo "== [5/5] size probe =="
docker build --build-arg BASE=monero-ringct-bench:release-v0_18 \
  -f docker/Dockerfile.size -t monero-ringct-size:latest docker/
./scripts/size_bench.sh

echo
echo "== DONE =="
echo "Grafana:    http://$(hostname -I | awk '{print $1}'):3000/d/ringct-observatory"
echo "Schedule nightly with the systemd units (see deploy/DEPLOY.md step 5)."
