#!/bin/bash

# Started at xfce4 login by /etc/xdg/autostart/biglybt_autostart.desktop, as the desktop user:
# /data for BiglyBT (prepare_biglybt.sh, through sudo), BiglyBT's settings on /data, then BiglyBT itself

FOLDERS="/data/autoload /data/torrents /data/processing /data/complete /data/config"

# /data's folders and BiglyBT's default config, prepared as root for this user
PREPARED=$(sudo -n /app/scripts/prepare_biglybt.sh 2>&1)
if [ $? -ne 0 ]; then
  xmessage -center "BiglyBT was not started: /data could not be prepared
${PREPARED}" &
  exit 1
fi
# Its warnings, if any, go to the session log
if [ -n "${PREPARED}" ]; then
  echo "${PREPARED}" >&2
fi

# BiglyBT keeps its settings, its list of torrents and its plugins in ~/.biglybt:
# a link to /data/config keeps them on the volume
if [ ! -e "${HOME}/.biglybt" ] && [ ! -L "${HOME}/.biglybt" ]; then
  ln -s /data/config "${HOME}/.biglybt"
elif [ "$(readlink "${HOME}/.biglybt")" != "/data/config" ]; then
  xmessage -center "${HOME}/.biglybt is not a link to /data/config:
BiglyBT's settings are not kept on /data" &
fi

# Folders this user can't write (prepare_biglybt.sh couldn't give them to it): BiglyBT starts anyway
NOTWRITABLE=""
for DIR in ${FOLDERS}; do
  if [ ! -w "${DIR}" ]; then
    NOTWRITABLE="${NOTWRITABLE} ${DIR}"
  fi
done
if [ -n "${NOTWRITABLE}" ]; then
  xmessage -center "BiglyBT: $(id -un) can't write to${NOTWRITABLE}" &
fi

# ubuntu-desktop-xfce's launcher: the first start runs install_biglybt.sh in an xterm window (apt-get, then
# BiglyBT's installer from /app/installer), then it starts BiglyBT
exec /app/scripts/biglybt.sh
