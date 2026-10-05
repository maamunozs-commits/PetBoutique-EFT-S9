#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
sudo install -d -m 755 /opt/petboutique-s8 /var/log/petboutique-s8
sudo install -m 644 "$ROOT/scripts/monitor.py" /opt/petboutique-s8/monitor.py
sudo install -m 644 "$ROOT/scripts/petboutique-monitor.service" /etc/systemd/system/petboutique-monitor.service
sudo install -m 644 "$ROOT/scripts/petboutique-monitor.timer" /etc/systemd/system/petboutique-monitor.timer
sudo install -m 644 "$ROOT/scripts/petboutique-logrotate" /etc/logrotate.d/petboutique-s8
sudo systemctl daemon-reload
sudo systemctl enable --now petboutique-monitor.timer
sudo systemctl start petboutique-monitor.service
