<!-- DRAFT for https://github.com/seraphis-migration/monero/issues/495
     Review before posting. Not posted automatically. -->

I can volunteer for the stressnet v3 data collection.

Running now: a full (unpruned) v0.19.0.0-beta.3.0 node, capped at 4 cores / 6 GB RAM on SSD, syncing. I can add a second node with the same caps on HDD for an SSD vs HDD comparison.

I can run the sidecar, expose ZMQ to your hub, provide restricted RPC, and send logs/backtraces for stalls or forks. Unrestricted RPC stays local.

Questions:
1. Schema for per-block acceptance delay?
2. Push to your hub, or will you pull?
3. Is a resource-capped container acceptable as a hardware profile?
