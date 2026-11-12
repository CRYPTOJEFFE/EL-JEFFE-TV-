# UGREEN DXP2800 deployment: EL JEFFE ENTERTAINMENT

This folder packages a clean, self-hosted media dashboard for UGREEN Docker Compose.

## Services

- Homarr — dashboard
- Jellyfin — movies and TV from media you control
- Navidrome — music
- Audiobookshelf — audiobooks and podcasts
- Kavita — e-books, comics and magazine/PDF libraries
- Gluetun — outbound VPN gateway, kill switch and DNS ad/malicious/tracker blocking for containers you explicitly route through it
- Optional Cloudflare Tunnel — protected remote access without router port forwarding

## Deploy in UGOS

1. Install **Docker** from App Center.
2. Create the persistent media/app-data folders.
3. Copy `.env.example` to `.env` and replace every example path/value.
4. Generate Homarr's encryption key with `openssl rand -hex 32`.
5. Open **Docker → Project → Create** and use this `docker-compose.yml`.
6. Deploy.
7. Open:
   - Homarr: `http://NAS_IP:7575`
   - Jellyfin: `http://NAS_IP:8096`
   - Navidrome: `http://NAS_IP:4533`
   - Audiobookshelf: `http://NAS_IP:13378`
   - Kavita: `http://NAS_IP:5000`

## DXP2800 hardware transcoding

The DXP2800 has an Intel CPU with Quick Sync. After confirming `/dev/dri` exists, uncomment the Jellyfin `devices` block and enable Intel QSV hardware acceleration in Jellyfin.

## Gluetun design

Keep Homarr, Jellyfin, Navidrome, Audiobookshelf, Kavita and Cloudflare Tunnel on the normal Docker bridge by default. Use Gluetun only as an explicit outbound gateway for containers that need VPN routing. That prevents a VPN outage from taking your dashboard offline.

Gluetun DNS filtering is enabled with:

- `BLOCK_ADS=on`
- `BLOCK_SURVEILLANCE=on`
- `BLOCK_MALICIOUS=on`

## EL JEFFE website bridge

For private-only remote access, use Tailscale. For a browser-friendly bridge from EL JEFFE ENTERTAINMENT, use Cloudflare Tunnel + Cloudflare Access and map hostnames to the Docker service names:

- `homarr.example.com -> http://homarr:7575`
- `watch.example.com -> http://jellyfin:8096`
- `music.example.com -> http://navidrome:4533`
- `audio.example.com -> http://audiobookshelf:80`
- `read.example.com -> http://kavita:5000`

Protect Homarr and administrative surfaces with authentication.

## Source policy

Use licensed/provider-issued M3U/XMLTV feeds, tuners you own, personal media, public-domain media, or APIs whose terms permit the use. This deployment does not scrape or rehost hidden stream URLs from third-party streaming sites and does not bypass their advertising, authentication, paywalls, or anti-bot controls.
