# Home Network Ad Blocker (Pi-hole on Proxmox)

A self-hosted, network-wide DNS ad blocker running as a Pi-hole LXC container on Proxmox VE, paired with Unbound for recursive, privacy-respecting DNS resolution. This blocks ads, trackers, and telemetry for every device on the network at the DNS level — no per-device software required.

## Features

- **Network-wide blocking** — every device (phones, laptops, smart TVs, IoT) is protected automatically via DHCP/DNS, no client installs.
- **Pi-hole** as the DNS sinkhole and web admin dashboard, deployed in a lightweight unprivileged LXC container.
- **Unbound** as a local recursive resolver, so DNS queries never leave the network to a third-party resolver.
- **Automated provisioning script** to spin up the LXC container on Proxmox from scratch.
- **Curated blocklists** covering ads, malware domains, and tracking/telemetry endpoints.
- **Query logging & stats dashboard** for visibility into blocked vs allowed traffic.

## Architecture

```
Internet
   |
[Router] -- DHCP hands out Pi-hole as DNS server
   |
[Proxmox Host]
   |
   +-- [Pi-hole LXC] --> [Unbound LXC/process] --> Internet (recursive resolution)
   |        |
   |        +-- Web UI :80
   |        +-- DNS :53
   |
[All LAN devices use Pi-hole as their DNS resolver]
```

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for more detail.

## Quick Start

1. Review and edit variables at the top of `scripts/setup-pihole-lxc.sh` (container ID, storage, network bridge, static IP).
2. Run the script on the Proxmox host:
   ```bash
   bash scripts/setup-pihole-lxc.sh
   ```
3. Once the container is up, finish Pi-hole setup with:
   ```bash
   pct exec <CTID> -- bash /root/install-pihole.sh
   ```
4. Log into the Pi-hole web UI at `http://<pihole-ip>/admin` and set the admin password.
5. Point your router's DHCP DNS setting to the Pi-hole's static IP so all devices use it automatically.

Full walkthrough in [docs/INSTALL.md](docs/INSTALL.md).

## Results

After deployment, typically 10–25% of DNS queries on a home network are ads/trackers and get blocked before they ever load. Screenshots of the dashboard are in [docs/screenshots](docs/screenshots).

## Stack

- Proxmox VE (LXC container host)
- Debian 12 (container OS)
- Pi-hole
- Unbound (recursive DNS)

## License

MIT — see [LICENSE](LICENSE).
