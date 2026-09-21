#!/usr/bin/env bash
# Run INSIDE the Jellyfin LXC to confirm QSV/VAAPI is reachable.
set -euo pipefail

echo "== Checking /dev/dri =="
ls -la /dev/dri || { echo "No /dev/dri found — passthrough not working."; exit 1; }

echo
echo "== Checking vainfo (requires intel-media-va-driver-non-free) =="
if ! command -v vainfo &>/dev/null; then
  echo "vainfo not installed. Install with: apt install vainfo intel-media-va-driver-non-free"
  exit 1
fi

vainfo --display drm --device /dev/dri/renderD128
