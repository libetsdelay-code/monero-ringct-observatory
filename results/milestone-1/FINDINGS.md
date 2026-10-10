# Milestone 1 — first real RingCT timings

- **Date (UTC):** 2026-10-10T16:38Z
- **Monero commit:** `22578c3f7d7b4b6dd85ff7daa42a827d97cc53d0` (release-v0.18)
- **Host CPU:** laptop CPU (14-core, 2023) (dev laptop — NOT the server target; treat
  absolute numbers as relative, ratios/trends are what matter)
- **Source:** Monero's own `tests/performance_tests`, median of N calls.

## Headline numbers (median)

### Bulletproofs+ (range proof) — prove vs verify, 1 output
| Op | BP+ | BP (old) |
|---|---|---|
| **verify** | **2.71 ms** | 2.76 ms |
| **prove**  | **15.8 ms** | 17.5 ms |

- Verifying is ~6× cheaper than proving — good: every node verifies, few prove.
- BP+ proves faster than BP for ~same verify cost → why Monero moved to BP+.

### CLSAG (ring signature) — scales ~linearly with ring size
| Ring size | median |
|---|---|
| 4  | 1.73 ms |
| 8  | 3.27 ms |
| **16 (Monero default)** | **6.40 ms** |
| 32 | 12.8 ms |
| 64 | 26.0 ms |
| 128 | 54.0 ms |
| 256 | 116 ms |

Cost ≈ linear in ring size (~0.4 ms per extra member). Larger rings = more privacy
but proportionally more CPU to verify.

### Batch verification pays off (aggregated bulletproofs, 2-out txs)
| Batch (txs) | total | per-tx |
|---|---|---|
| 2   | 77.7 ms | 38.8 ms |
| 10  | 207 ms  | 20.7 ms |
| 100 | 1685 ms | **16.9 ms** |

Per-tx verification cost roughly halves from batch 2 → 100. This is the scaling
curve papers like BulletCT try to improve.

### Full transaction verify (CLSAG + Bulletproof together)
- 2-in / 2-out:  **5.08 ms**
- 10-in / 2-out: 7.07 ms
- 100-in / 2-out: 29.8 ms

## Notes / next
- 64 measurements parsed (1 header line ignored).
- TODO M1.5: extract proof **size** in bytes (not just time).
- TODO M2: dedicated batch-verify curve, more batch points.
- TODO: pin exact commit per run (done — recorded), Prometheus + Grafana, nightly
  cron, then deploy to server.
