#!/usr/bin/env bash
#
# add-blocklists.sh
# Adds a curated set of ad/tracker/malware blocklists to Pi-hole's gravity database.

set -euo pipefail

LISTS=(
  "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts"
  "https://v.firebog.net/hosts/AdguardDNS.txt"
  "https://v.firebog.net/hosts/Easyprivacy.txt"
  "https://v.firebog.net/hosts/Prigent-Malware.txt"
  "https://raw.githubusercontent.com/anudeepND/blacklist/master/adservers.txt"
)

for list in "${LISTS[@]}"; do
  echo "[*] Adding blocklist: ${list}"
  sqlite3 /etc/pihole/gravity.db \
    "INSERT OR IGNORE INTO adlist (address, enabled) VALUES ('${list}', 1);"
done

echo "[*] Updating gravity (rebuilding block list database)..."
pihole -g
