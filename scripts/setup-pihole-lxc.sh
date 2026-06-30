#!/usr/bin/env bash
#
# setup-pihole-lxc.sh
# Provisions a Debian 12 LXC container on Proxmox VE for Pi-hole.
# Run this ON THE PROXMOX HOST as root.

set -euo pipefail

# ---- Configuration: edit these for your environment ----
CTID=200                                   # Container ID (must be unused)
HOSTNAME="pihole"
STORAGE="local-lvm"                        # Proxmox storage pool
TEMPLATE_STORAGE="local"                   # Where templates are stored
TEMPLATE="debian-12-standard_12.7-1_amd64.tar.zst"
BRIDGE="vmbr0"
STATIC_IP="192.168.1.53/24"                # Static IP for the Pi-hole container
GATEWAY="192.168.1.1"
DISK_SIZE="4"                              # GB
MEMORY="512"                               # MB
CORES="1"
# ----------------------------------------------------------

echo "[*] Checking for container template..."
if ! pveam list "${TEMPLATE_STORAGE}" | grep -q "${TEMPLATE}"; then
  echo "[*] Downloading template ${TEMPLATE}"
  pveam update
  pveam download "${TEMPLATE_STORAGE}" "${TEMPLATE}"
fi

echo "[*] Creating LXC container ${CTID} (${HOSTNAME})..."
pct create "${CTID}" "${TEMPLATE_STORAGE}:vztmpl/${TEMPLATE}" \
  --hostname "${HOSTNAME}" \
  --storage "${STORAGE}" \
  --rootfs "${STORAGE}:${DISK_SIZE}" \
  --memory "${MEMORY}" \
  --cores "${CORES}" \
  --net0 "name=eth0,bridge=${BRIDGE},ip=${STATIC_IP},gw=${GATEWAY}" \
  --unprivileged 1 \
  --features nesting=1 \
  --onboot 1

echo "[*] Starting container..."
pct start "${CTID}"
sleep 5

echo "[*] Copying install script into container..."
pct push "${CTID}" "$(dirname "$0")/install-pihole.sh" /root/install-pihole.sh
pct exec "${CTID}" -- chmod +x /root/install-pihole.sh

echo "[+] Container ${CTID} (${HOSTNAME}) is up at ${STATIC_IP}"
echo "[+] Next step: pct exec ${CTID} -- bash /root/install-pihole.sh"
