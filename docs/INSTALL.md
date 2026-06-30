# Installation Guide

## Prerequisites

- A working Proxmox VE host with internet access.
- A `local-lvm` (or equivalent) storage pool with space for a small container.
- Knowledge of your LAN subnet, gateway IP, and an unused static IP to assign to Pi-hole.
- Root SSH/console access to the Proxmox host.

## Step 1 — Clone this repo onto the Proxmox host

```bash
git clone https://github.com/<your-username>/home-dns-blocker.git
cd home-dns-blocker
```

## Step 2 — Edit configuration variables

Open `scripts/setup-pihole-lxc.sh` and adjust:

- `CTID` — an unused container ID
- `STATIC_IP` / `GATEWAY` — match your LAN
- `BRIDGE` — your Proxmox network bridge (usually `vmbr0`)
- `STORAGE` — your Proxmox storage pool name

## Step 3 — Provision the container

```bash
bash scripts/setup-pihole-lxc.sh
```

This creates and starts a Debian 12 LXC container with the static IP you configured.

## Step 4 — Install Pi-hole and Unbound

```bash
pct exec <CTID> -- bash /root/install-pihole.sh
```

This installs Unbound (recursive resolver) and Pi-hole (unattended install), wires Pi-hole's upstream DNS to Unbound, and loads the curated blocklists.

## Step 5 — Set the admin password

```bash
pct exec <CTID> -- pihole -a -p
```

## Step 6 — Point your network at Pi-hole

In your router's DHCP settings, set the primary DNS server to the Pi-hole container's static IP. Most routers are under **Settings → LAN/DHCP → DNS**. Restart affected devices (or wait for DHCP lease renewal) so they pick up the new DNS server.

## Step 7 — Verify

- Visit `http://<pihole-ip>/admin` and log in.
- The dashboard should start showing queries from devices on your network within a few minutes.
- Test blocking by visiting a site with known ad domains and confirming requests are blocked in the **Query Log**.

## Troubleshooting

| Symptom | Likely cause |
|---|---|
| Devices not using Pi-hole | DHCP lease hasn't renewed — reboot device or router |
| No internet after switching DNS | Unbound not resolving — check `systemctl status unbound` in the container |
| Web UI unreachable | Container network/firewall — check `pct config <CTID>` and Proxmox firewall rules |
| Some ads still showing | Some ads are served from the same domain as content (CDN-hosted) — DNS blocking can't catch these; consider an in-browser supplement |
