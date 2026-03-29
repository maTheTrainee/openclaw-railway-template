# OpenClaw Railway Template

This is the Railway template with optional Tailscale private access added on top of the standard OpenClaw setup flow.

## Security notice

By default this template still behaves like the normal Railway template.

If you set `TAILSCALE_AUTHKEY`, the container starts Tailscale automatically and joins your tailnet. If you do not set it, the app starts normally without Tailscale.

## What you get

- OpenClaw Gateway + Control UI
- Setup Wizard at `/setup`
- Optional Web Terminal at `/tui`
- Persistent Railway volume support
- Optional Tailscale bootstrap on startup

## Tailscale quick start

1. Generate a reusable, pre-authorized auth key in Tailscale.
2. Add `TAILSCALE_AUTHKEY` in Railway Variables.
3. Optional: set `TAILSCALE_HOSTNAME`.
4. Optional HTTPS over tailnet:
   - `ENABLE_TAILSCALE_SERVE=true`
   - `TAILSCALE_SERVE_HTTPS_PORT=443`
5. Deploy.

If `TAILSCALE_AUTHKEY` is not set, nothing changes from the normal template.

## Railway variables

Required for the app itself:
- `SETUP_PASSWORD`
- `OPENCLAW_STATE_DIR=/data/.openclaw`
- `OPENCLAW_WORKSPACE_DIR=/data/workspace`

Optional for Tailscale:
- `TAILSCALE_AUTHKEY`
- `TAILSCALE_HOSTNAME`
- `TAILSCALE_ACCEPT_DNS=false`
- `ENABLE_TAILSCALE_SERVE=false`
- `TAILSCALE_SERVE_HTTPS_PORT=443`

## Access patterns

Without Tailscale:
- use the normal Railway URL

With Tailscale and no serve:
- access over your tailnet using the Tailscale machine name and port 8080

With Tailscale serve enabled:
- access over Tailscale HTTPS on your tailnet domain

## Guide

See `TAILSCALE_GUIDE.md` for the full step-by-step Railway setup.

## Local testing

```bash
docker build -t openclaw-railway-template .

docker run --rm -p 8080:8080 \
  -e PORT=8080 \
  -e SETUP_PASSWORD=test \
  -e OPENCLAW_STATE_DIR=/data/.openclaw \
  -e OPENCLAW_WORKSPACE_DIR=/data/workspace \
  -v $(pwd)/.tmpdata:/data \
  openclaw-railway-template
```
