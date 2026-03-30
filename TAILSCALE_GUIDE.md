# Tailscale Guide for Railway

This template can connect itself to Tailscale during startup.

## 1. Create a Tailscale auth key

In the Tailscale admin panel:
- go to Settings -> Keys
- create an auth key
- make it reusable
- make it pre-authorized

Copy the generated key.

## 2. Add Railway variables

In Railway, open your service and set:

```bash
TAILSCALE_AUTHKEY=tskey-auth-...
TAILSCALE_HOSTNAME=openclaw-railway
TAILSCALE_ACCEPT_DNS=false
ENABLE_TAILSCALE_SERVE=false
TAILSCALE_SERVE_HTTPS_PORT=443
```

Notes:
- `TAILSCALE_AUTHKEY` enables Tailscale startup
- if `TAILSCALE_AUTHKEY` is missing, the app starts normally without Tailscale
- `TAILSCALE_HOSTNAME` controls the machine name in your tailnet
- `ENABLE_TAILSCALE_SERVE=true` enables HTTPS exposure through Tailscale Serve
- `TAILSCALE_ACCEPT_DNS` only controls whether this container accepts DNS settings from the tailnet; it does not advertise Railway DNS names into Tailscale

## 3. Deploy

Redeploy the Railway service after saving the variables.

On startup the container will:
- start `tailscaled`
- run `tailscale up`
- print the node's tailnet IP and hostname into the Railway logs
- optionally run `tailscale serve`
- then start the OpenClaw wrapper

## 4. Access the app

If you only enabled tailnet networking:
- connect your own device to Tailscale
- open the machine on port 8080 inside the tailnet
- use the tailnet IP from the Railway logs or the hostname you configured with `TAILSCALE_HOSTNAME`

If you enabled Tailscale Serve:
- connect your own device to Tailscale
- open the generated tailnet HTTPS URL
- the URL comes from the Tailscale node name in your tailnet, not from Railway's public domain

No Tailscale admin popup is expected for "advertising Railway DNS addresses" because this template does not advertise Railway DNS records at all.

## 5. Make it private-only

After confirming Tailscale access works, you can disable the public Railway networking if you want the service to be reachable only from your tailnet.

## Troubleshooting

### Tailscale does not start
- verify that `TAILSCALE_AUTHKEY` is valid
- generate a new key and redeploy

### Device cannot reach the app
- make sure your own device is connected to the same tailnet
- check that the Railway deployment completed successfully

### HTTPS URL does not exist
- set `ENABLE_TAILSCALE_SERVE=true`
- make sure MagicDNS / tailnet HTTPS is enabled in your Tailscale tailnet
- redeploy the service
