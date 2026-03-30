# OpenClaw Railway Template

## Security Notice

> **This template exposes your OpenClaw gateway to the public internet.** **Please read the [OpenClaw security documentation](https://docs.openclaw.ai/gateway/security) before deploying** to understand the risks and recommended configuration. If you only use chat channels (Telegram, Discord, Slack) and don't need the gateway dashboard, you can remove the public endpoint from Railway after setup.

<img width="1860" height="2624" alt="CleanShot 2026-02-23 at 21 59 06@2x" src="https://github.com/user-attachments/assets/2605d44c-4319-4e92-838c-3caa726b9595" />

## What you get

- **OpenClaw Gateway + Control UI** (served at `/` and `/openclaw`)
- A friendly **Setup Wizard** at `/setup` (protected by a password)
- Optional **Web Terminal** at `/tui` for browser-based TUI access
- Persistent state via **Railway Volume** (so config/credentials/memory survive redeploys)
- Optional **Tailscale bootstrap** during container startup

## How it works (high level)

- The container runs a wrapper web server.
- The wrapper protects `/setup` with `SETUP_PASSWORD`.
- During setup, the wrapper runs `openclaw onboard --non-interactive ...` inside the container, writes state to the volume, and then starts the gateway.
- After setup, **`/` is OpenClaw**. The wrapper reverse-proxies all traffic (including WebSockets) to the local gateway process.

## Optional Tailscale

If you set `TAILSCALE_AUTHKEY`, the container joins your tailnet during startup. If you also set `ENABLE_TAILSCALE_SERVE=true`, the container configures `tailscale serve` for HTTPS access on your `*.ts.net` name.

This is intentionally separate from Railway networking:

- Railway public URLs stay Railway public URLs
- Railway private DNS (`*.railway.internal`) is only for Railway-to-Railway traffic
- Tailscale access uses the node's tailnet IP or `*.ts.net` name

Recommended flow:

1. Deploy with Railway public networking still enabled.
2. Confirm Tailscale access works.
3. Disable **Public Networking** in Railway if you want tailnet-only access.

Tailscale variables:

- `TAILSCALE_AUTHKEY`
- `TAILSCALE_HOSTNAME`
- `TAILSCALE_ACCEPT_DNS=false`
- `ENABLE_TAILSCALE_SERVE=false`
- `TAILSCALE_SERVE_HTTPS_PORT=443`

See [TAILSCALE_GUIDE.md](./TAILSCALE_GUIDE.md) for the step-by-step setup.

### Tailscale-side setup

Before deploying on Railway, do this in Tailscale:

1. Open the Tailscale admin console.
2. Go to **Settings** -> **Keys**.
3. Create an auth key.
4. Make it **reusable** and **pre-authorized**.
5. Copy that key into Railway as `TAILSCALE_AUTHKEY`.

If you want HTTPS on a `*.ts.net` address with `tailscale serve`:

1. Make sure **MagicDNS** is enabled for your tailnet.
2. Make sure tailnet HTTPS / `*.ts.net` access is enabled in Tailscale.
3. Set `ENABLE_TAILSCALE_SERVE=true` in Railway.

Recommended rollout:

1. Leave Railway public networking enabled on the first deploy.
2. Confirm you can reach the app through Tailscale.
3. Disable Railway public networking once tailnet access is confirmed.

### Remove the Railway public URL after Tailscale works

Rookie version:

1. Open your project in Railway.
2. Open the **service** that runs OpenClaw.
3. Open **Settings**.
4. Find **Networking** and then **Public Networking**.
5. If you see a Railway-generated domain like `something.up.railway.app`, remove it there.
6. If you added your own custom domain, remove that too if you want Tailscale-only access.
7. Test access again from a device that is logged into the same tailnet.

After that:

- the Railway public URL should no longer be your normal way in
- your Tailscale address becomes the main way in
- if `ENABLE_TAILSCALE_SERVE=true`, use `https://<hostname>.<tailnet>.ts.net`
- if `ENABLE_TAILSCALE_SERVE=false`, use the tailnet IP or hostname on port `8080`

If you are unsure, do it in this order:

1. Verify Tailscale access first.
2. Remove the Railway public domain second.

## Getting chat tokens (so you don't have to scramble)

### Telegram bot token

1. Open Telegram and message **@BotFather**
2. Run `/newbot` and follow the prompts
3. BotFather will give you a token that looks like: `123456789:AA...`
4. Paste that token into `/setup`

### Discord bot token

1. Go to the Discord Developer Portal: https://discord.com/developers/applications
2. **New Application** → pick a name
3. Open the **Bot** tab → **Add Bot**
4. Copy the **Bot Token** and paste it into `/setup`
5. Invite the bot to your server (OAuth2 URL Generator → scopes: `bot`, `applications.commands`; then choose permissions)

## Web Terminal (TUI)

The template includes an optional web-based terminal that runs `openclaw tui` in your browser.

### Enabling

Set `ENABLE_WEB_TUI=true` in your Railway Variables. The terminal is **disabled by default**.

Once enabled, access it at `/tui` or via the "Open Terminal" button on the setup page.

### Security

The web TUI implements multiple security layers:

| Control | Description |
|---------|-------------|
| **Opt-in only** | Disabled by default, requires explicit `ENABLE_WEB_TUI=true` |
| **Password protected** | Uses the same `SETUP_PASSWORD` as the setup wizard |
| **Single session** | Only 1 concurrent TUI session allowed at a time |
| **Idle timeout** | Auto-closes after 5 minutes of inactivity (configurable via `TUI_IDLE_TIMEOUT_MS`) |
| **Max duration** | Hard limit of 30 minutes per session (configurable via `TUI_MAX_SESSION_MS`) |

### Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `ENABLE_WEB_TUI` | `false` | Set to `true` to enable |
| `TUI_IDLE_TIMEOUT_MS` | `300000` (5 min) | Closes session after inactivity |
| `TUI_MAX_SESSION_MS` | `1800000` (30 min) | Maximum session duration |

## Local testing

```bash
docker build -t openclaw-railway-template .

docker run --rm -p 8080:8080 \
  -e PORT=8080 \
  -e SETUP_PASSWORD=test \
  -e ENABLE_WEB_TUI=true \
  -e OPENCLAW_STATE_DIR=/data/.openclaw \
  -e OPENCLAW_WORKSPACE_DIR=/data/workspace \
  -v $(pwd)/.tmpdata:/data \
  openclaw-railway-template

# Setup wizard: http://localhost:8080/setup (password: test)
# Web terminal: http://localhost:8080/tui (after setup)
```

## FAQ

**Q: How do I access the setup page?**

A: Go to `/setup` on your deployed instance. When prompted for credentials, use the generated `SETUP_PASSWORD` from your Railway Variables as the password. The username field is ignored—you can leave it empty or enter anything.

**Q: I see "gateway disconnected" or authentication errors in the Control UI. What should I do?**

A: Go back to `/setup` and click the "Open OpenClaw UI" button from there. The setup page passes the required auth token to the UI. Accessing the UI directly without the token will cause connection errors.

**Q: I don't see the TUI option on the setup page.**

A: Make sure `ENABLE_WEB_TUI=true` is set in your Railway Variables and redeploy. The web terminal is disabled by default.

**Q: How do I approve pairing for Telegram or Discord?**

A: Go to `/setup` and use the "Approve Pairing" dialog to approve pending pairing requests from your chat channels.

**Q: I see "pairing required" when opening the Control UI. How do I fix it?**

A: New browsers/devices need a one-time approval from the gateway. Go to `/setup`, click "Manage Devices" in the Devices section, and click "Approve Latest Request". Refresh the Control UI and it should connect. Local connections (127.0.0.1) are auto-approved; remote connections (LAN, public URL) require explicit approval.

**Q: How do I change the AI model after setup?**

A: Use the OpenClaw CLI to switch models. Access the web terminal at `/tui` (if enabled) or SSH into your container and run:

```bash
openclaw models set provider/model-id
```

For example: `openclaw models set anthropic/claude-sonnet-4-20250514` or `openclaw models set openai/gpt-4-turbo`. Use `openclaw models list --all` to see available models.

**Q: How do I access configuration after the initial setup?**

A: Visit `/setup` on your deployed instance at any time — it works both before and after setup. Once configured, the setup page shows your current status along with management tools: device approval, health checks (Run Doctor), data export, and a reset option. You'll need your `SETUP_PASSWORD` to access it.

**Q: My config seems broken or I'm getting strange errors. How do I fix it?**

A: Go to `/setup` and click the "Run Doctor" button. This runs `openclaw doctor --repair` which performs health checks on your gateway and channels, creates a backup of your config, and removes any unrecognized or corrupted configuration keys.

**Q: Why didn't Tailscale show a popup to advertise Railway DNS names?**

A: This template does not advertise Railway DNS names into Tailscale. If Tailscale is enabled, access the service using the container's tailnet IP or `*.ts.net` name instead.

## Screenshots

## Setup

<img width="2110" height="2032" alt="CleanShot 2026-02-23 at 21 57 59@2x" src="https://github.com/user-attachments/assets/28640eec-fa35-42f2-ba56-cb1fbb9525de" />

## TUI

<img width="2510" height="608" alt="CleanShot 2026-02-23 at 22 08 20@2x" src="https://github.com/user-attachments/assets/61147ec2-ddd5-4b5b-b9ac-0dd81a1ae4c7" />

## Device approval

<img width="1712" height="1376" alt="CleanShot 2026-02-23 at 21 59 21@2x" src="https://github.com/user-attachments/assets/f30ab683-dbc2-4980-ace7-152265e00c79" />

## Support

Need help? [Request support on Railway Station](https://station.railway.com/all-templates/d0880c01-2cc5-462c-8b76-d84c1a203348)
