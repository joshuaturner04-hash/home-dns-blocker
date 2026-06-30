# Architecture

## Overview

This project deploys a DNS-level ad and tracker blocker for a home network using:

- **Pi-hole** — acts as the DNS server every device on the LAN points to. It checks each query against blocklists and returns a "blocked" response (NXDOMAIN or null route) for known ad/tracker domains, and forwards everything else upstream.
- **Unbound** — runs alongside Pi-hole as a local recursive resolver. Instead of forwarding allowed queries to a third-party DNS provider (Google, Cloudflare, etc.), Unbound resolves them directly against the root DNS hierarchy, keeping browsing metadata off third-party resolvers.
- **Proxmox LXC** — Pi-hole and Unbound run in a lightweight unprivileged Linux container rather than a full VM, keeping resource usage minimal (≈512MB RAM, 1 vCPU, 4GB disk) while staying isolated from the Proxmox host and other guests.

## Request flow

1. A device on the LAN (e.g. a phone) makes a DNS query, e.g. for `ads.example.com`.
2. The router has DHCP configured to hand out the Pi-hole container's static IP as the DNS server.
3. Pi-hole receives the query and checks it against the gravity database (aggregated blocklists).
   - If the domain is on a blocklist → Pi-hole returns a blocked response immediately.
   - If not → Pi-hole forwards the query to Unbound on `127.0.0.1:5335`.
4. Unbound performs full recursive resolution (talking directly to authoritative nameservers) and returns the answer to Pi-hole.
5. Pi-hole caches and returns the answer to the requesting device.

## Why DNS-level blocking instead of browser extensions

- Covers every device on the network (smart TVs, IoT, game consoles) that can't run extensions.
- No per-device configuration or maintenance.
- Centralized stats and control via one dashboard.
- Survives browser/app updates that often break extension-based blockers.

## Network changes required

- Router DHCP DNS option set to the Pi-hole container's static IP.
- Optionally, the router's WAN/upstream DNS can also point to Pi-hole for full coverage even if a device manually overrides its DNS (combined with DNS hijacking/redirect rules on the router, not covered by this script).
