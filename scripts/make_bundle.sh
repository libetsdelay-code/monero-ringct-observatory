#!/usr/bin/env bash
# Create a transferable bundle of the repo (tracked files only) to copy to server.
# Usage: make_bundle.sh   ->   /tmp/ringct-observatory-<date>.tar.gz
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$HERE"
OUT="/tmp/ringct-observatory-$(date +%Y%m%d).tar.gz"
git archive --format=tar.gz --prefix=monero-ringct-observatory/ -o "$OUT" HEAD
echo "[*] bundle: $OUT"
echo "[*] copy to server LXC, e.g.:"
echo "    scp $OUT <user>@<lxc-ip>:~/"
echo "    ssh <user>@<lxc-ip> 'tar xzf ~/$(basename "$OUT") && \\"
echo "        cd monero-ringct-observatory && bash deploy/bootstrap_lxc.sh'"
