#!/usr/bin/env bash
set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  echo "Please run as root: sudo $0" >&2
  exit 1
fi

ALIYUN_DOCKER_MIRROR="${ALIYUN_DOCKER_MIRROR:-https://amuntpc9.mirror.aliyuncs.com}"

mkdir -p /etc/docker

if [[ -f /etc/docker/daemon.json ]]; then
  backup="/etc/docker/daemon.json.bak.$(date +%Y%m%d%H%M%S)"
  cp /etc/docker/daemon.json "${backup}"
  echo "Backed up existing /etc/docker/daemon.json to ${backup}"
fi

python3 - "${ALIYUN_DOCKER_MIRROR}" "${EXTRA_DOCKER_MIRRORS:-}" <<'PY' >/etc/docker/daemon.json
import json
import sys

primary = sys.argv[1].strip().rstrip("/")
extra = [item.strip().rstrip("/") for item in sys.argv[2].split(",") if item.strip()]
mirrors = []
for item in [primary, *extra]:
    if item not in mirrors:
        mirrors.append(item)

print(json.dumps({"registry-mirrors": mirrors}, indent=2))
PY

systemctl daemon-reload
systemctl restart docker

echo "Docker registry mirrors configured:"
docker info 2>/dev/null | sed -n '/Registry Mirrors:/,/Live Restore Enabled:/p'
