# Jellyfin + Intel Quick Sync (QSV) Hardware Transcoding in an LXC

> Part of [homelab-hub](https://github.com/YOUR_USERNAME/homelab-hub). Media server running in a Proxmox LXC with the host's integrated GPU passed through for hardware-accelerated transcoding.

## Why this exists

Software transcoding on a 4-core i7-6700T pins the CPU on anything above 1-2 simultaneous streams. The CPU has an integrated GPU (Intel HD Graphics 530) sitting unused, so the goal was to pass that iGPU into an **unprivileged LXC** (not a full VM) and get Jellyfin to use it via QSV — keeping resource overhead minimal.

## Architecture

```
Proxmox Host (i7-6700T, iGPU: Intel HD 530)
 └── /dev/dri (render node) ──passthrough──► Jellyfin LXC (unprivileged)
                                                   └── Jellyfin
                                                        └── ffmpeg (VAAPI/QSV)
```

LXC was chosen over a VM specifically because GPU passthrough to an LXC only requires exposing the `/dev/dri` render node with the right group permissions — no PCI passthrough, no IOMMU juggling, no dedicating the whole iGPU to one guest.

## What's in this repo

| Path | Contents |
|---|---|
| `config/lxc.conf.example` | Sanitized LXC config snippet showing the `/dev/dri` device passthrough and cgroup permissions |
| `config/jellyfin-hwaccel.example.xml` | Jellyfin hardware acceleration settings used (VAAPI device, QSV codecs enabled) |
| `scripts/verify-qsv.sh` | Quick script to confirm the render node is visible and usable inside the container (`vainfo`) |
| `docs/setup-steps.md` | Full step-by-step: host-side group/permissions, LXC config edits, Jellyfin-side settings |

## Setup summary

1. On the Proxmox host, confirm the render node: `ls -la /dev/dri` → note the group ID (usually `render`, GID varies by host).
2. Add the device passthrough lines to the LXC's config (see `config/lxc.conf.example`).
3. Inside the container, install `vainfo`/`intel-media-va-driver-non-free` and confirm QSV is detected (`scripts/verify-qsv.sh`).
4. In Jellyfin → Dashboard → Playback, set hardware acceleration to **Intel QuickSync (QSV)**, point it at `/dev/dri/renderD128`, and enable the codecs your library needs (H.264, HEVC, etc.).
5. Test with a transcode and confirm via `intel_gpu_top` on the host that the iGPU is actually being used (not falling back to CPU silently).

Full detail in [`docs/setup-steps.md`](docs/setup-steps.md).

## Status / Known issues

- ✅ Stable for 1080p transcodes, multiple concurrent streams without CPU spikes.
- ⚠️ Slow boot/startup times after host restarts are being investigated — not yet confirmed whether it's related to the LXC device passthrough re-initializing or unrelated storage latency.
- 🔜 Considering hardware refresh (see `homelab-proxmox-infra`) partly to get a newer iGPU with AV1 decode support.

## License

MIT — see [LICENSE](LICENSE).
