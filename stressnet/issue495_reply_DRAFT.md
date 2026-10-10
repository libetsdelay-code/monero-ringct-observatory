<!-- DRAFT for https://github.com/seraphis-migration/monero/issues/495
     Review before posting. Not posted automatically. -->

Hi @Fountain5405, I'd like to volunteer for the stressnet v3 data collection.

**What I'm running now**

- A stressnet v3 node (`v0.19.0.0-beta.3.0-release`, via `ghcr.io/hundehausen/monero-fcmp-docker`), full / unpruned, currently syncing from scratch.
- Host: desktop 14-core CPU (2023), node in a container limited to **4 cores / 6 GB RAM**, on a **SATA SSD**.
- I already run Prometheus + Grafana at home, and the node is scraped every 15 s (height, peers, txpool size, alt chains, DB size).

**Two hardware profiles**

Since the goal is minimum hardware, I plan to add a second node with the same CPU/RAM limits but its DB on a **5400-rpm-class HDD** (WD Red 2 TB). An SSD vs HDD comparison under FCMP++ load seems directly useful. I can also tighten the CPU/RAM caps further if you want a lower-end profile.

**What I can offer**

- Run your sidecar next to `monerod` once there's code. ZMQ pub is already enabled locally (`tcp://127.0.0.1:28083`), so I can expose it to your hub if that's how you want to collect.
- Restricted RPC for volunteers, if useful. I agree with @Rucknium that unrestricted RPC shouldn't be public, so it stays bound to localhost.
- Logs and backtraces for any stall / fork / crash, reported as issues here.
- My own per-block / host metrics exported as Parquet, if you share the schema you want.

**Questions**

1. Is there a preferred schema for per-block acceptance delay? I can parse it from the log at an elevated log level, or wait for your sidecar.
2. Where should data go: push to your hub, or will you pull?
3. Is a capped-resource LXC acceptable as a "hardware profile", or do you only want bare-metal numbers?

Happy to adjust to whatever is most useful.
