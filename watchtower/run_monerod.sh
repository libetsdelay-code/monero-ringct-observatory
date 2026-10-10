#!/usr/bin/env bash
# Run a pruned monerod (Watchtower node) in Docker. Blockchain lives on /data
# (the data2tb pool). Unrestricted RPC bound to localhost only for the exporter;
# P2P open to the network.
set -euo pipefail
DATA="${DATA:-/data/bitmonero}"
mkdir -p "$DATA"

docker rm -f monerod >/dev/null 2>&1 || true
docker run -d --name monerod --restart unless-stopped \
  -v "$DATA":/home/monero/.bitmonero \
  -p 127.0.0.1:18081:18081 \
  -p 18080:18080 \
  sethsimmons/simple-monerod:latest \
  --prune-blockchain \
  --rpc-bind-ip=0.0.0.0 --rpc-bind-port=18081 --confirm-external-bind \
  --p2p-bind-port=18080 \
  --no-igd --out-peers=24 --in-peers=48 \
  --db-sync-mode=safe:sync

echo "[*] monerod started (pruned). RPC local :18081, P2P :18080."
echo "[*] data dir: $DATA"
