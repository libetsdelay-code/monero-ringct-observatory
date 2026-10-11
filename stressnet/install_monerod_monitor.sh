#!/usr/bin/env bash
# Install Rucknium's monerod-monitor collector (seraphis-migration/monero#495)
# next to a stressnet node, and run it as a systemd service.
# Debian prebuilt r-cran-* packages are used where possible to avoid long
# compiles; only RJSONIO comes from CRAN. The Shiny UI is not installed:
# we only need the collector (data goes to SQLite).
set -euo pipefail
RPC="${RPC:-http://127.0.0.1:28081}"
INTERVAL="${INTERVAL:-30}"
DIR=/opt/monerod-monitor

export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq git r-base-core r-base-dev \
  r-cran-argparser r-cran-dbi r-cran-rsqlite r-cran-rcurl r-cran-ps >/dev/null
# RJSONIO is not packaged in Debian. ps must come from CRAN too: Debian 12's
# r-cran-ps 1.7.2 has no "maxrss" field, and the collector then crashes on
# every insert into process_info ("No value given for placeholder mem_maxrss").
Rscript -e 'for (p in c("RJSONIO", "ps")) if (!requireNamespace(p, quietly=TRUE) || (p == "ps" && packageVersion("ps") < "1.9.0")) install.packages(p, repos="https://cloud.r-project.org", quiet=TRUE)'

if [ ! -d "$DIR/.git" ]; then
  git clone -q https://github.com/Rucknium/monerod-monitor.git "$DIR"
fi
cd "$DIR"
echo "monerod-monitor commit: $(git rev-parse --short HEAD)"
mkdir -p data
[ -f data/xmr-stressnet-diagnostics.db ] || Rscript inst/initialize-db.R

cat > /etc/systemd/system/monerod-monitor.service <<EOF
[Unit]
Description=monerod-monitor collector (stressnet #495)
After=network-online.target docker.service

[Service]
WorkingDirectory=$DIR
ExecStart=/usr/bin/Rscript inst/collect-monerod-info.R --rpcmonerod $RPC --net testnet --collectioninterval $INTERVAL
Restart=always
RestartSec=20

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable --now monerod-monitor
echo "monerod-monitor: $(systemctl is-active monerod-monitor)"
