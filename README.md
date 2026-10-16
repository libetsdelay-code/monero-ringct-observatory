# Monero RingCT Performance Observatory

Self-hosted, reproducible measurement tools for Monero. Three parts share one
Prometheus + Grafana stack:

| Part | What it does | Directory |
|---|---|---|
| **RingCT benchmark** | Builds Monero's own `performance_tests` from source and tracks CLSAG and Bulletproofs+ verify time and proof size across releases and commits. | `docker/`, `scripts/`, `results/` |
| **Watchtower** | A pruned mainnet node plus a stdlib-only Prometheus exporter: height, sync, peers, mempool, alternate chains (reorg signal), and monerod CPU/RAM. | `watchtower/` |
| **FCMP++ stressnet** | Two identical stressnet nodes (4 cores / 6 GB each), one on SSD and one on HDD, to measure the minimum hardware for an FCMP++ node. Contribution to [seraphis-migration/monero#495](https://github.com/seraphis-migration/monero/issues/495). | `stressnet/` |

## Why
- Research papers often publish self-measured numbers without reproducible code.
- Every node verifies every transaction, so proof size and verify time drive
  chain growth, sync time and decentralization.
- FCMP++ changes the cost of running a node. Real measurements on modest
  hardware help answer "what is the minimum?".

## Results so far
- **Proof size** (validated with Monero's own serialization): CLSAG ring 16 =
  577 B, Bulletproofs+ 1 output = 578 B, 16 outputs = 834 B.
- **Verify time:** CLSAG scales linearly with ring size. Batch verification of
  Bulletproofs+ drops the per-proof cost by about half from batch 2 to batch 100.
  See `results/milestone-1/FINDINGS.md`.
- **Cross-version:** `release-v0.18` vs `master` CLSAG and BP+ timings are within
  about 2% (FCMP++ code is additive and does not slow the current proofs).
- **Stressnet:** peak RSS about 4.3 GB (SSD) and 4.7 GB (HDD) under a 6 GB cap.
  A full stressnet node alone keeps an HDD close to 100% busy.

## Quick start (benchmark)
```bash
docker build -f docker/Dockerfile.bench -t monero-ringct-bench:latest .
HOST_LABEL="desktop 14-core" ./scripts/run_bench.sh   # parses and pushes metrics
./scripts/bench_ref.sh master                          # benchmark another ref
```

Observability stack:
```bash
cp observability/.env.example observability/.env      # set scrape target IPs
docker compose -f observability/docker-compose.yml up -d
# Grafana on :3000 (change the admin password before exposing it)
```

Deployment notes (LXC, systemd timer for nightly runs): `deploy/DEPLOY.md`.

## Privacy rules of this repo
- Only aggregate metrics are exported or published. Peer IP addresses that the
  collectors see are never committed or published.
- Unrestricted RPC stays on localhost.
- Scrape target addresses live in the git-ignored `observability/.env`.

## Caveats
- Benchmarking Monero's own code is reliable. Comparing with research schemes
  depends on usable reference code existing.
- Timings depend on hardware. Compare runs only from the same host.

## License
MIT. See `LICENSE`.
