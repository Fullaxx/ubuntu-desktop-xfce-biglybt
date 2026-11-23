#!/bin/bash
# This script runs as root
# /data for BiglyBT: its folders and BiglyBT's default config, for the desktop user who runs it through sudo
# (/usr/local/bin/biglybt_autostart.sh does, at every login: the base image's sudo rules let the desktop
# user run /app/scripts/prepare_*.sh). Running it again only adds what's missing.

FOLDERS="/data/autoload /data/torrents /data/processing /data/complete /data/config"

# The folders the default config points at, and BiglyBT's own (~/.biglybt is a link to /data/config)
mkdir -p ${FOLDERS} || exit 1

# BiglyBT's default config, only if there is no config yet: a /data kept from an earlier container keeps its settings
if [ ! -e /data/config/biglybt.config ]; then
  install -m 0644 /usr/share/biglybt/biglybt.config.default /data/config/biglybt.config || exit 1
fi

# A non-root desktop user (VNCUSERMAP) gets whatever in the folders has another owner, such as what root
# wrote when the container ran without VNCUSERMAP. A root desktop needs nothing, so it changes no owner.
# Best effort: some filesystems refuse chown (NFS with root_squash, CIFS), and biglybt_autostart.sh
# shows which folders the desktop user can't write
if [ "${SUDO_UID:-0}" != "0" ]; then
  if ! find ${FOLDERS} \( ! -user "${SUDO_UID}" -o ! -group "${SUDO_GID}" \) -exec chown -h "${SUDO_UID}:${SUDO_GID}" {} +; then
    echo "$0: some of /data could not be given to ${SUDO_USER} (${SUDO_UID}:${SUDO_GID})" >&2
  fi
fi
