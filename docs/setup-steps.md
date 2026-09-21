# Setup Steps — Jellyfin + QSV in an LXC

## 1. Host side (Proxmox)

```bash
ls -la /dev/dri
getent group render
```

Note the render group's GID — you'll need it for the LXC idmap.

## 2. LXC config

Edit `/etc/pve/lxc/<CTID>.conf` (see `config/lxc.conf.example` in this repo for the exact lines) to:
- Allow the device cgroups for `/dev/dri`.
- Bind-mount `/dev/dri` into the container.
- Map the `render` group GID correctly between host and container (this is the part that trips most guides up on unprivileged containers).

Restart the container after editing.

## 3. Inside the container

```bash
apt update && apt install -y vainfo intel-media-va-driver-non-free
./scripts/verify-qsv.sh
```

You should see VAAPI profiles listed (H264, HEVC, etc.) with no permission errors.

## 4. Jellyfin

Dashboard → Playback → Transcoding:
- Hardware acceleration: **Intel QuickSync (QSV)**
- VA-API device: `/dev/dri/renderD128`
- Enable hardware decoding for the codecs your library actually uses.
- Enable hardware encoding if you also want QSV on the encode side.

## 5. Validate under load

On the host:

```bash
intel_gpu_top
```

Start a transcode from a client that forces transcoding (e.g. play a codec/bitrate your client can't direct-play), and confirm the render engine usage rises on the host — not just CPU usage on the container.
