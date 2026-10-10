#!/usr/bin/env python3
"""Minimal Monero node Prometheus exporter (stdlib only).

Polls monerod's local RPC and serves network-health metrics for the Watchtower:
height/sync, peers, difficulty, mempool, and alt-chain (reorg) signals.
Serves /metrics on :9000.
"""
import json
import urllib.request
from http.server import BaseHTTPRequestHandler, HTTPServer

RPC = "http://127.0.0.1:18081/json_rpc"


def rpc(method, params=None):
    payload = {"jsonrpc": "2.0", "id": "0", "method": method}
    if params:
        payload["params"] = params
    req = urllib.request.Request(
        RPC, data=json.dumps(payload).encode(),
        headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=10) as r:
        return json.loads(r.read()).get("result", {})


def collect():
    out = []

    def g(name, val):
        out.append(f"monero_{name} {val}")

    try:
        info = rpc("get_info")
        g("up", 1)
        for k in ("height", "target_height", "difficulty", "tx_count",
                  "tx_pool_size", "alt_blocks_count",
                  "outgoing_connections_count", "incoming_connections_count",
                  "white_peerlist_size", "grey_peerlist_size",
                  "database_size", "free_space"):
            v = info.get(k)
            if isinstance(v, (int, float)):
                g(k, v)
        g("synchronized", 1 if info.get("synchronized") else 0)
        g("busy_syncing", 1 if info.get("busy_syncing") else 0)
        # Reorg signal: alternate chains the node currently sees.
        try:
            ac = rpc("get_alternate_chains") or {}
            chains = ac.get("chains") or []
            g("alt_chains_count", len(chains))
            g("alt_chain_max_length",
              max((c.get("length", 0) for c in chains), default=0))
        except Exception:
            pass
    except Exception:
        g("up", 0)
    return "\n".join(out) + "\n"


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path.startswith("/metrics"):
            body = collect().encode()
            self.send_response(200)
            self.send_header("Content-Type", "text/plain; version=0.0.4")
            self.end_headers()
            self.wfile.write(body)
        else:
            self.send_response(200)
            self.end_headers()
            self.wfile.write(b"monero exporter - see /metrics\n")

    def log_message(self, *a):
        pass


if __name__ == "__main__":
    HTTPServer(("0.0.0.0", 9000), Handler).serve_forever()
