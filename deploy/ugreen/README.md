# EL JEFFE ENTERTAINMENT — UGREEN DXP2800

This deployment is designed for the user's UGREEN NAS:

- NAS name: `ELJEFFETV`
- Recorded LAN address: `192.168.1.222`
- Recorded movie/TV share: `PLEX_2/Media/Movies and TV Shows`
- Recorded music share: `MUSIC`
- Recorded ROM share: `roms`

The installer discovers those share names under `/volume*` instead of assuming which storage pool they live on.

## Architecture

Core services run directly on the EL JEFFE Docker bridge:

- Homarr — dashboard
- Jellyfin — movies and TV
- Navidrome — music
- Audiobookshelf — audiobooks and podcasts
- Kavita — e-books, comics and magazines

Optional profiles:

- `iptv` — Dispatcharr IPTV/EPG manager for licensed/provider-issued M3U, Xtream and XMLTV sources
- `vpn` — Gluetun outbound VPN gateway and DNS ad/tracker/malware filtering
- `iptv-vpn` — Dispatcharr sharing Gluetun's network namespace so its outbound stream traffic uses the VPN
- `remote` — Cloudflare Tunnel for protected HTTPS access

Keeping Homarr and the local media servers off Gluetun by default means a VPN outage will not take the dashboard or local playback offline.

## Fastest deployment

SSH/Terminal method:

```sh
cd /path/to/deploy/ugreen
cp .env.example .env
chmod +x install-ugreen.sh
./install-ugreen.sh
```

The installer:

1. searches `/volume*` for the recorded video, music and ROM shares;
2. chooses the matching UGREEN storage root for new media folders where possible;
3. creates Audiobooks, Podcasts, Books, Magazines and Comics folders when missing;
4. creates persistent app-data folders;
5. generates Homarr's 64-character encryption key;
6. validates the Compose configuration;
7. starts the five core media/dashboard services.

## UGOS Docker Project method

If you prefer the GUI:

1. Install/open **Docker** in UGOS.
2. Open **Docker → Project → Create**.
3. Put `docker-compose.yml` and `.env` in the same project directory.
4. Edit `.env` so all paths match the NAS.
5. Deploy the project.

Core local URLs:

- Homarr: `http://192.168.1.222:7575`
- Jellyfin: `http://192.168.1.222:8096`
- Navidrome: `http://192.168.1.222:4533`
- Audiobookshelf: `http://192.168.1.222:13378`
- Kavita: `http://192.168.1.222:5000`
- Dispatcharr after the IPTV profile is enabled: `http://192.168.1.222:9191`

## TV / IPTV / EPG

Dispatcharr is the channel-management layer.

Start it normally:

```sh
docker compose --profile iptv up -d
```

Or, after filling your VPN credentials, route Dispatcharr's outbound traffic through Gluetun:

```sh
docker compose --profile iptv-vpn up -d
```

Do not run `dispatcharr` and `dispatcharr-vpn` at the same time because they share the same database and port.

In Dispatcharr, add only M3U/Xtream/XMLTV sources you are authorized to use. Dispatcharr can export a cleaned M3U/XMLTV set and emulate an HDHomeRun tuner. Add that HDHomeRun endpoint to Jellyfin/Plex/Emby so your channel list and EPG become a proper TV guide rather than a collection of ad-heavy web pages.

## Gluetun

Do not commit VPN credentials.

Fill the VPN variables in `.env`, then start Gluetun:

```sh
docker compose --profile vpn up -d
```

Gluetun is configured with DNS blocking for ads, surveillance/tracker domains and malicious domains. Containers should only be routed through Gluetun deliberately.

## Secure EL JEFFE website bridge

For browser-friendly access from EL JEFFE ENTERTAINMENT, use the `remote` profile after you create a Cloudflare Tunnel and copy its token into `.env`:

```sh
docker compose --profile remote up -d
```

Configure Cloudflare Tunnel public hostnames to the Docker service names:

- `homarr.yourdomain.com` → `http://homarr:7575`
- `watch.yourdomain.com` → `http://jellyfin:8096`
- `music.yourdomain.com` → `http://navidrome:4533`
- `audio.yourdomain.com` → `http://audiobookshelf:80`
- `read.yourdomain.com` → `http://kavita:5000`
- `tv.yourdomain.com` → `http://dispatcharr:9191` when using the normal IPTV profile, or `http://gluetun:9191` when using the IPTV-vpn profile

Protect Homarr, Dispatcharr and other administrative surfaces with Cloudflare Access. Do not expose UGOS itself directly to the public Internet.

The included `el-jeffe-nas-bridge.html` gives EL JEFFE ENTERTAINMENT a local/remote launcher. The included `el-jeffe-site-links.json` is the machine-readable equivalent.

## Jellyfin hardware transcoding

The DXP2800 uses Intel hardware suitable for Quick Sync. After confirming `/dev/dri` exists on the NAS, uncomment the Jellyfin `devices` mapping in `docker-compose.yml`, redeploy, then enable Intel QSV in Jellyfin.

## Homarr

Homarr works immediately as the dashboard. Add the local service URLs above as Apps/Bookmarks.

The Docker socket is intentionally left commented out. Mounting `/var/run/docker.sock` gives Homarr powerful Docker-management access; enable it only if you specifically want container inventory/lifecycle controls and accept that security tradeoff.

## Content-source boundary

Use:

- media stored on your NAS;
- tuners you own;
- licensed/provider-issued M3U/XMLTV/Xtream feeds;
- public-domain media;
- APIs whose terms permit the integration.

This project intentionally does not scrape/rehost hidden streams from third-party streaming sites, bypass authentication/paywalls, or remove another site's advertising in order to republish its streams.
