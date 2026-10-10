# Deploying to server (the 24/7 home)

Why server and not the laptop: a *benchmark* needs stable, dedicated, always-on
hardware. The desktop host, with a core-pinned LXC, gives clean numbers that
stay comparable across months. Timings here are the authoritative series; the
laptop was only for building the harness.

## 1. Create a dedicated LXC (on the Proxmox host)
- Debian/Ubuntu LXC, **nesting=1** (needed for Docker), ~20 GB disk, 8 GB RAM.
- Give it a static IP.
- Pin it to fixed physical cores for consistent timings, e.g. in the LXC config:
  ```
  lxc.cgroup2.cpuset.cpus = 4-9
  ```
  (Reserve those cores from other guests so the benchmark never shares them.)

## 2. Install Docker in the LXC
```bash
curl -fsSL https://get.docker.com | sh
```

## 3. Clone and bring up the stack
```bash
git clone <this-repo> ~/monero-ringct-observatory
cd ~/monero-ringct-observatory
cp observability/.env.example observability/.env   # then set the exporter IPs
docker compose -f observability/docker-compose.yml up -d
```
Grafana: http://<lxc-ip>:3000  (anonymous Viewer; admin/admin to edit).

## 4. First run + verify
```bash
./scripts/bench_ref.sh release-v0.18
```
Confirm series appear in Grafana, tagged with ref + commit.

## 5. Schedule nightly (systemd timer)
```bash
sudo cp deploy/ringct-bench.service deploy/ringct-bench.timer /etc/systemd/system/
# edit the service: set User=, WorkingDirectory=, and REFS= as desired
sudo systemctl daemon-reload
sudo systemctl enable --now ringct-bench.timer
systemctl list-timers ringct-bench.timer
```
Or cron:
```
15 3 * * *  cd ~/monero-ringct-observatory && REFS="release-v0.18 master" ./scripts/nightly.sh
```

## Notes
- To compare versions, add refs: `REFS="release-v0.18 master v0.18.3.4"`.
- Keep the LXC's cores reserved; shared cores = noisy, non-comparable timings.
- The GPUs are untouched (CPU-bound), so this never competes with AI/ART work.
