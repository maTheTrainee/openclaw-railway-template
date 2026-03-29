#!/bin/bash
set -euo pipefail

chown -R openclaw:openclaw /data
chmod 700 /data

if [ ! -d /data/.linuxbrew ]; then
  cp -a /home/linuxbrew/.linuxbrew /data/.linuxbrew
fi

rm -rf /home/linuxbrew/.linuxbrew
ln -sfn /data/.linuxbrew /home/linuxbrew/.linuxbrew

if [ -n "${TAILSCALE_AUTHKEY:-}" ]; then
  echo "Starting Tailscale..."
  mkdir -p /var/run/tailscale /data/tailscale

  /usr/sbin/tailscaled \
    --state=/data/tailscale/tailscaled.state \
    --socket=/var/run/tailscale/tailscaled.sock \
    --tun=userspace-networking &

  for i in $(seq 1 30); do
    if [ -S /var/run/tailscale/tailscaled.sock ]; then
      break
    fi
    sleep 1
  done

  if [ ! -S /var/run/tailscale/tailscaled.sock ]; then
    echo "tailscaled socket did not become ready" >&2
    exit 1
  fi

  tailscale --socket=/var/run/tailscale/tailscaled.sock up \
    --authkey="${TAILSCALE_AUTHKEY}" \
    --hostname="${TAILSCALE_HOSTNAME:-openclaw-railway}" \
    --accept-dns="${TAILSCALE_ACCEPT_DNS:-false}"

  if [ "${ENABLE_TAILSCALE_SERVE:-false}" = "true" ]; then
    tailscale --socket=/var/run/tailscale/tailscaled.sock serve \
      --bg \
      --https="${TAILSCALE_SERVE_HTTPS_PORT:-443}" \
      "http://127.0.0.1:${PORT:-8080}"
  fi
else
  echo "TAILSCALE_AUTHKEY not set; starting without Tailscale."
fi

exec gosu openclaw node src/server.js
