#!/bin/sh
set -eu

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
ENV_FILE="$ROOT/.env"
ENV_TEMPLATE="$ROOT/.env.example"

say() { printf "%s\n" "$*"; }
die() { printf "ERROR: %s\n" "$*" >&2; exit 1; }

command -v docker >/dev/null 2>&1 || die "Docker CLI was not found. Install/enable Docker in UGOS first."
if docker compose version >/dev/null 2>&1; then
  dc() { docker compose "$@"; }
elif command -v docker-compose >/dev/null 2>&1; then
  dc() { docker-compose "$@"; }
else
  die "Docker Compose was not found."
fi

if [ ! -f "$ENV_FILE" ]; then cp "$ENV_TEMPLATE" "$ENV_FILE"; fi

find_dir() {
  rel="$1"
  for v in /volume*; do
    [ -d "$v" ] || continue
    if [ -d "$v/$rel" ]; then printf "%s\n" "$v/$rel"; return 0; fi
  done
  return 1
}

replace_env() {
  key="$1"; value="$2"
  tmp="$ENV_FILE.tmp"
  awk -v k="$key" -v v="$value" 'BEGIN{FS=OFS="="} $1==k {$0=k"=\""v"\""} {print}' "$ENV_FILE" > "$tmp"
  mv "$tmp" "$ENV_FILE"
}

VIDEO="$(find_dir "PLEX_2/Media/Movies and TV Shows" || true)"
MUSIC="$(find_dir "MUSIC" || true)"
ROMS="$(find_dir "roms" || true)"

if [ -n "$VIDEO" ]; then
  MEDIA_BASE="${VIDEO%%/PLEX_2/Media/Movies and TV Shows}"
elif [ -n "$MUSIC" ]; then
  MEDIA_BASE="${MUSIC%/MUSIC}"
else
  MEDIA_BASE="/volume1"
  [ -d "$MEDIA_BASE" ] || MEDIA_BASE="$(find / -maxdepth 1 -type d -name "volume*" 2>/dev/null | head -n 1 || true)"
fi
[ -n "$MEDIA_BASE" ] || die "No UGREEN /volume* storage root was found."

[ -n "$VIDEO" ] && replace_env VIDEO_ROOT "$VIDEO"
[ -n "$MUSIC" ] && replace_env MUSIC_ROOT "$MUSIC"
[ -n "$ROMS" ] && replace_env ROMS_ROOT "$ROMS"

for pair in "AUDIOBOOKS_ROOT:Audiobooks" "PODCASTS_ROOT:Podcasts" "BOOKS_ROOT:Books" "MAGAZINES_ROOT:Magazines" "COMICS_ROOT:Comics"; do
  key="${pair%%:*}"; folder="${pair#*:}"; path="$MEDIA_BASE/$folder"
  mkdir -p "$path"
  replace_env "$key" "$path"
done

APPDATA="$(find_dir "docker/el-jeffe" || true)"
if [ -z "$APPDATA" ]; then APPDATA="$MEDIA_BASE/docker/el-jeffe"; mkdir -p "$APPDATA"; fi
replace_env APPDATA_ROOT "$APPDATA"

for d in homarr jellyfin/config jellyfin/cache navidrome audiobookshelf/config audiobookshelf/metadata kavita dispatcharr gluetun; do
  mkdir -p "$APPDATA/$d"
done

if grep -q "^HOMARR_SECRET_ENCRYPTION_KEY=REPLACE_WITH_64_HEX_CHARACTERS$" "$ENV_FILE"; then
  if command -v openssl >/dev/null 2>&1; then
    KEY="$(openssl rand -hex 32)"
  else
    KEY="$(dd if=/dev/urandom bs=32 count=1 2>/dev/null | od -An -tx1 | tr -d " \n")"
  fi
  replace_env HOMARR_SECRET_ENCRYPTION_KEY "$KEY"
fi

say "EL JEFFE UGREEN discovery:"
say "  NAS:       ELJEFFETV / 192.168.1.222"
say "  Media base:$MEDIA_BASE"
say "  App data:  $APPDATA"
if [ -n "$VIDEO" ]; then say "  Video:     $VIDEO"; else say "  Video:     not auto-detected; edit .env before Jellyfin library setup"; fi
if [ -n "$MUSIC" ]; then say "  Music:     $MUSIC"; else say "  Music:     not auto-detected; edit .env before Navidrome setup"; fi
if [ -n "$ROMS" ]; then say "  ROMs:      $ROMS"; else say "  ROMs:      not auto-detected"; fi
if [ -d /dev/dri ]; then say "  Intel GPU: /dev/dri detected (Quick Sync can be enabled)"; else say "  Intel GPU: /dev/dri not detected"; fi

say ""
say "Validating Compose configuration..."
dc --env-file "$ENV_FILE" -f "$ROOT/docker-compose.yml" config >/dev/null

say "Starting core EL JEFFE services..."
dc --env-file "$ENV_FILE" -f "$ROOT/docker-compose.yml" up -d homarr jellyfin navidrome audiobookshelf kavita

say ""
say "Core deployment requested."
say "Homarr:          http://192.168.1.222:7575"
say "Jellyfin:        http://192.168.1.222:8096"
say "Navidrome:       http://192.168.1.222:4533"
say "Audiobookshelf:  http://192.168.1.222:13378"
say "Kavita:          http://192.168.1.222:5000"
say "Dispatcharr:     http://192.168.1.222:9191 (after IPTV profile is started)"
say ""
say "Authorized IPTV without VPN: dc --profile iptv up -d"
say "Authorized IPTV through Gluetun: dc --profile iptv-vpn up -d"
say "Gluetun only: dc --profile vpn up -d"
say "Cloudflare bridge: dc --profile remote up -d"
