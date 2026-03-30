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
  TAILSCALE_SOCKET=/var/run/tailscale/tailscaled.sock

  tailscaled \
    --state=/data/tailscale/tailscaled.state \
    --socket="${TAILSCALE_SOCKET}" \
    --tun=userspace-networking &

  for i in $(seq 1 30); do
    if [ -S "${TAILSCALE_SOCKET}" ]; then
      break
    fi
    sleep 1
  done

  if [ ! -S "${TAILSCALE_SOCKET}" ]; then
    echo "tailscaled socket did not become ready" >&2
    exit 1
  fi

  tailscale --socket="${TAILSCALE_SOCKET}" up \
    --authkey="${TAILSCALE_AUTHKEY}" \
    --hostname="${TAILSCALE_HOSTNAME:-openclaw-railway}" \
    --accept-dns="${TAILSCALE_ACCEPT_DNS:-false}"

  TAILSCALE_IPV4="$(tailscale --socket="${TAILSCALE_SOCKET}" ip -4 2>/dev/null | head -n 1 || true)"

  echo "Tailscale connected."
  if [ -n "${TAILSCALE_IPV4}" ]; then
    echo "Tailnet IPv4: ${TAILSCALE_IPV4}"
  fi
  echo "Tailnet hostname: ${TAILSCALE_HOSTNAME:-openclaw-railway}"
  tailscale --socket="${TAILSCALE_SOCKET}" status || true

  if [ "${ENABLE_TAILSCALE_SERVE:-false}" = "true" ]; then
    tailscale --socket="${TAILSCALE_SOCKET}" serve \
      --bg \
      --yes \
      --https="${TAILSCALE_SERVE_HTTPS_PORT:-443}" \
      "http://127.0.0.1:${PORT:-8080}"

    echo "Tailscale Serve status:"
    tailscale --socket="${TAILSCALE_SOCKET}" serve status || true
  fi
else
  echo "TAILSCALE_AUTHKEY not set; starting without Tailscale."
  if [ "${ENABLE_TAILSCALE_SERVE:-false}" = "true" ]; then
    echo "ENABLE_TAILSCALE_SERVE is ignored until TAILSCALE_AUTHKEY is set."
  fi
fi

exec gosu openclaw node src/server.js
