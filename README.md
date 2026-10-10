# Monero RingCT Performance Observatory

An independent, reproducible benchmark lab for Monero's privacy proofs.

It measures how **big** and how **slow** Monero's real cryptographic proofs are —
**CLSAG** (ring signature) and **Bulletproofs+** (range proof) — and tracks those
numbers across Monero releases/commits. It also fact-checks the scalability claims
of research papers such as **BulletCT** (IACR eprint 2025/188).

Design notes live in the Alexandria zettelkasten: *"Main Monero Idea Project"* and
*"Monero Assurance Node (umbrella project)"*.

## Why
- Papers publish self-measured numbers, often without reproducible code.
- Every node verifies every transaction — proof size and verify time decide
  blockchain bloat, sync time, and decentralization.
- The community lacks independent, continuous, reproducible measurements.

## What it measures (roadmap)
1. **Proof size** (bytes) — CLSAG, Bulletproofs+.           ← later
2. **Single verification time**.                             ← MILESTONE 1 (now)
3. **Batch-verification scaling** (cost vs. batch size).     ← MILESTONE 2
4. **Full-chain sync/verification time** per release.        ← MILESTONE 3
5. Apples-to-apples vs. research schemes where code exists.  ← later / best-effort

## How it works
- `docker/Dockerfile.bench` builds Monero's own `performance_tests` binary from
  source inside a container (no host deps; fully reproducible).
- `scripts/run_bench.sh` runs the CLSAG/Bulletproofs tests, saving raw output +
  metadata (exact Monero commit, host CPU) under `results/run_<stamp>/`.
- `scripts/parse_results.py` turns raw output into `parsed.json` and a Prometheus
  `metrics.prom` textfile.
- Later: Prometheus scrapes the textfiles; Grafana shows the public dashboard.

## Quick start
```bash
# 1. Build the benchmark image (compiles Monero's performance_tests; ~15-40 min)
docker build -f docker/Dockerfile.bench -t monero-ringct-bench:latest .

# 2. Run the CLSAG + Bulletproofs benchmarks
./scripts/run_bench.sh

# 3. Parse into JSON + Prometheus metrics
python3 scripts/parse_results.py results/run_<stamp>/raw.txt
```

## Status
- [x] Repo + containerized harness scaffolded
- [ ] Milestone 1: first real CLSAG/Bulletproofs+ verify timings
- [ ] Prometheus + Grafana
- [ ] Deploy to server (24/7, nightly + per-release runs)

## Notes
- Prototyped on a laptop; target host is server (24/7).
- Honest caveat: benchmarking Monero's own code is doable now. Benchmarking
  research schemes depends on usable reference code existing (often it does not).
