<!-- DRAFT for https://github.com/seraphis-migration/monero/issues/495
     Review before posting. Not posted automatically. -->

I'm already running a stressnet v3 node (full, v0.19.0.0-beta.3.0) capped at 4 cores / 6 GB RAM on SSD, and collecting metrics every 15 s: height, peers, txpool size, alt chains, DB size. I'm adding a second node with the same caps on HDD for an SSD vs HDD comparison.

Is this useful for the monitor? If so:
1. Which data do you want on top of this (e.g. per-block acceptance delay), and in what format?
2. Should I push to your hub, or will you pull?

I can also run your sidecar when it's ready and send logs/backtraces for stalls or forks.
