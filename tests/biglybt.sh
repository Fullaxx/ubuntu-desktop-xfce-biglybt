#!/bin/bash
# Start an ubuntu-desktop-xfce-biglybt image the way users do and check the whole path: the image's tools and
# BiglyBT installer, the desktop, /data's folders and default config, ~/.biglybt on /data, BiglyBT installed at
# the first start and listening on 28474 (the default config's port), and a .torrent dropped in /data/autoload
# imported into /data/torrents. Options after the image go to docker run, such as a non-root desktop user.
# Run it on a Docker host, as .github/workflows/ci.yml does before it publishes:
#   tests/biglybt.sh IMAGE
#   tests/biglybt.sh IMAGE -e VNCUSERMAP=ubuntu/1000

set -euo pipefail

IMAGE="${1:?usage: ${0##*/} IMAGE [docker run options]}"
shift
NAME="udxb-test-$$"
PORT=28474
FOLDERS="/data/autoload /data/torrents /data/processing /data/complete /data/config"

fail() {
  echo "FAIL: $*" >&2
  docker logs --tail 40 "${NAME}" 2>&1 || true
  exit 1
}

running() {
  [ "$(docker inspect -f '{{.State.Running}}' "${NAME}" 2>/dev/null)" == "true" ]
}

# wait_for SECONDS MESSAGE COMMAND...: run COMMAND every second until it succeeds, or fail with MESSAGE
wait_for() {
  local SECS="$1" MSG="$2"
  shift 2
  for _ in $(seq "${SECS}"); do
    running || fail "${IMAGE} exited (${MSG})"
    if "$@" >/dev/null 2>&1; then
      return 0
    fi
    sleep 1
  done
  fail "${MSG}"
}

# -v: the container's anonymous /data volume goes with it
trap 'docker rm -f -v "${NAME}" >/dev/null 2>&1 || true' EXIT

docker run -d --name "${NAME}" "$@" "${IMAGE}" >/dev/null

# The image: BiglyBT's installer, and the tools the Dockerfile installs (7zip-rar gives 7z its RAR codec)
docker exec "${NAME}" test -x /app/installer/BiglyBT_Installer.sh || fail "/app/installer/BiglyBT_Installer.sh is missing or not executable"
for TOOL in 7z buildtorrent mktorrent ping ip lsof netstat tree file zip unzip zstd mtr ssh; do
  docker exec "${NAME}" which "${TOOL}" >/dev/null || fail "${TOOL} is not installed"
done
SEVENZIP=$(docker exec "${NAME}" 7z i)
grep -q -E '^ *[0-9]+ +[A-Z]* +[0-9A-F]+ +Rar5$' <<<"${SEVENZIP}" || fail "7z lists no RAR codec (7zip-rar)"

# The desktop: a VNC server speaks first, with an RFB ProtocolVersion banner such as "RFB 003.008",
# and Xfce starts after it, from its xstartup
BANNER=""
for _ in $(seq 60); do
  running || fail "${IMAGE} exited before the desktop came up"
  BANNER=$(docker exec "${NAME}" timeout 5 bash -c 'exec 3<>/dev/tcp/127.0.0.1/5901 && head -c 12 <&3' 2>/dev/null || true)
  if [[ "${BANNER}" == RFB* ]]; then
    break
  fi
  sleep 1
done
[[ "${BANNER}" == RFB* ]] || fail "no VNC server answered on 127.0.0.1:5901 within 60 s"
wait_for 30 "the VNC server is up but xfce4-session did not start within 30 s" docker exec "${NAME}" pgrep -x xfce4-session

# The desktop user (root, or VNCUSERMAP's) and its HOME
SESSIONUID=$(docker exec "${NAME}" ps -o uid= -C xfce4-session)
SESSIONUID="${SESSIONUID//[[:space:]]/}"
SESSIONHOME=$(docker exec "${NAME}" getent passwd "${SESSIONUID}" | cut -d: -f6)

# /data, from biglybt_autostart.sh at login: the folders, BiglyBT's default config, and ~/.biglybt on /data/config
wait_for 60 "${SESSIONHOME}/.biglybt did not appear within 60 s of the login" docker exec "${NAME}" test -L "${SESSIONHOME}/.biglybt"
[ "$(docker exec "${NAME}" readlink "${SESSIONHOME}/.biglybt")" == "/data/config" ] || fail "${SESSIONHOME}/.biglybt is not a link to /data/config"
for DIR in ${FOLDERS}; do
  docker exec "${NAME}" test -d "${DIR}" || fail "${DIR} is missing"
done
docker exec "${NAME}" grep -q -F 'Watch Torrent Folder Path14:/data/autoload' /data/config/biglybt.config || fail "/data/config/biglybt.config is not the default config"

# BiglyBT: the first start installs it (from /app/installer), then starts it
# (pgrep without a shell around it, which would match its own command line)
wait_for 900 "BiglyBT did not start within 900 s" docker exec "${NAME}" pgrep -f 'com\.biglybt\.ui\.Main'

# The default config's listen port (without it, a new install picks a random port)
wait_for 120 "BiglyBT is running but does not listen on ${PORT}" docker exec "${NAME}" timeout 3 bash -c "exec 3<>/dev/tcp/127.0.0.1/${PORT}"

# A non-root desktop user owns everything in the folders (prepare_biglybt.sh), BiglyBT's files included
if [ "${SESSIONUID}" != "0" ]; then
  OTHERS=$(docker exec "${NAME}" find ${FOLDERS} ! -user "${SESSIONUID}")
  [ -z "${OTHERS}" ] || fail "not owned by UID ${SESSIONUID}: ${OTHERS}"
fi

# A .torrent dropped in /data/autoload: BiglyBT keeps a copy in /data/torrents. It's written as .part and then
# renamed, so BiglyBT never reads half a file. BiglyBT scans the folder every 60 s
docker exec "${NAME}" sh -c 'head -c 65536 /dev/urandom > /tmp/udxb-test.bin &&
  mktorrent -a http://127.0.0.1:1/announce -o /data/autoload/udxb-test.part /tmp/udxb-test.bin >/dev/null &&
  mv /data/autoload/udxb-test.part /data/autoload/udxb-test.torrent' || fail "mktorrent could not make a test torrent"
wait_for 150 "the .torrent in /data/autoload was not imported into /data/torrents within 150 s" \
  docker exec "${NAME}" sh -c 'ls /data/torrents | grep -q "\.torrent$"'

echo "OK: ${IMAGE}${*:+ ($*)} runs Xfce, prepares /data for UID ${SESSIONUID}, installs BiglyBT, which listens on ${PORT} and imports from /data/autoload"
