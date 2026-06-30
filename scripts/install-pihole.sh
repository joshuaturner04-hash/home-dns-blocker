#!/usr/bin/env bash
#
# install-pihole.sh
# Installs Pi-hole and Unbound inside the Debian LXC container.
# Run this INSIDE the container: pct exec <CTID> -- bash /root/install-pihole.sh

set -euo pipefail

echo "[*] Updating system..."
apt-get update -y && apt-get upgrade -y

echo "[*] Installing prerequisites..."
apt-get install -y curl ca-certificates unbound

echo "[*] Configuring Unbound as a local recursive resolver..."
cat > /etc/unbound/unbound.conf.d/pi-hole.conf <<'EOF'
server:
    interface: 127.0.0.1
    port: 5335
    do-ip4: yes
    do-udp: yes
    do-tcp: yes
    do-ip6: no
    prefer-ip6: no
    harden-glue: yes
    harden-dnssec-stripped: yes
    use-caps-for-id: no
    edns-buffer-size: 1232
    prefetch: yes
    num-threads: 1
    so-rcvbuf: 1m
    private-address: 192.168.0.0/16
    private-address: 169.254.0.0/16
    private-address: 172.16.0.0/12
    private-address: 10.0.0.0/8
    private-address: fd00::/8
    private-address: fe80::/10
EOF

systemctl restart unbound
systemctl enable unbound

echo "[*] Installing Pi-hole (unattended)..."
curl -sSL https://install.pi-hole.net | bash /dev/stdin --unattended

echo "[*] Pointing Pi-hole's upstream DNS to local Unbound..."
pihole -a -d  # set upstream via CLI is version-dependent; fallback to setupVars
SETUP_VARS="/etc/pihole/setupVars.conf"
if [ -f "${SETUP_VARS}" ]; then
  sed -i '/^PIHOLE_DNS_/d' "${SETUP_VARS}"
  echo "PIHOLE_DNS_1=127.0.0.1#5335" >> "${SETUP_VARS}"
  pihole restartdns
fi

echo "[*] Adding curated blocklists..."
bash "$(dirname "$0")/../config/add-blocklists.sh" || true

echo "[+] Pi-hole install complete."
echo "[+] Set the web admin password with: pihole -a -p"
echo "[+] Web UI: http://<container-ip>/admin"
