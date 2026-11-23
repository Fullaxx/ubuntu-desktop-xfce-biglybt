# Ubuntu Desktop running BiglyBT in Xfce4

[ubuntu-desktop-xfce](https://github.com/Fullaxx/ubuntu-desktop-xfce) with [BiglyBT](https://www.biglybt.com/), a Java-based BitTorrent client. \
BiglyBT starts with the desktop and keeps everything (its settings, its torrents and your downloads) on one volume, /data.

## Base Docker Image
[ghcr.io/fullaxx/ubuntu-desktop-xfce](https://github.com/Fullaxx/ubuntu-desktop-xfce):26.04 (Ubuntu 26.04, Xfce 4.20, TigerVNC 1.15)

## Software
* [BiglyBT](https://www.biglybt.com/) - its latest release, currently 4.2.0.0. The installer is downloaded from BiglyBT's website when the image is built (/app/installer)
* OpenJDK 25 and WebKitGTK, for BiglyBT
* [Firefox](https://www.mozilla.org/firefox/) - Mozilla's build from the Mozilla Team PPA (Ubuntu's own firefox package is the snap)
* 7-Zip (with RAR support), mktorrent, buildtorrent, curl, wget, file, lsof, ping, mtr, the OpenSSH client, iproute2, net-tools, tree, zip/unzip, bzip2, xz-utils, zstd and bash-completion

## Get the image or build it locally
```
docker pull ghcr.io/fullaxx/ubuntu-desktop-xfce-biglybt

docker build -t="ghcr.io/fullaxx/ubuntu-desktop-xfce-biglybt" https://github.com/Fullaxx/ubuntu-desktop-xfce-biglybt.git
```
`:latest` and `:26.04` (ubuntu-desktop-xfce 26.04) are the same image. It is rebuilt at every push to `master`, and a rebuild picks up a new BiglyBT release,
Mozilla's updates to Firefox and Ubuntu's to the other packages.

## Volume: /data
Mount a directory on /data to keep your downloads and BiglyBT's settings when the container is re-created
```
-v /srv/docker/biglybt/data:/data
```
```
/data
|-- autoload   - Drop your .torrent files here (or .magnet files, each holding one magnet link)
|-- torrents   - BiglyBT keeps a copy of every .torrent here
|-- processing - Downloads in progress
|-- complete   - Finished downloads are moved here
`-- config     - BiglyBT's settings, its list of torrents and its plugins (~/.biglybt is a link to it)
```
- BiglyBT looks in autoload once a minute: it adds the torrents it finds, keeps a copy of each in torrents, and deletes the file from autoload at its next look.
- The folders and BiglyBT's default settings are made at login. /data/config/biglybt.config is only written when it's missing, so the settings you change in BiglyBT are kept.
- With `VNCUSERMAP`, the desktop user is given everything in the five folders that belongs to someone else, at every login (only those files change). As root (the default), no owner changes.

## Incoming connections
BiglyBT listens on port 28474, TCP and UDP \
(set by its default settings; Tools > Options > Connection changes it). \
Publish it so that peers can connect to you (not when BiglyBT is on a VPN container's network: [NETWORKING.md](NETWORKING.md#biglybts-incoming-port))
```
-p 28474:28474 -p 28474:28474/udp
```

## VPN
BiglyBT has no VPN of its own: run it on the network of a VPN container, and its traffic goes through the VPN. \
How to set that up, with an OpenVPN and a WireGuard example: [NETWORKING.md](NETWORKING.md)

## Firefox
Firefox is in the image: Applications > Ubuntu Desktop > Network > Browsers > Firefox. \
Give the container more shared memory, or Firefox's tabs crash ([why](https://github.com/Fullaxx/ubuntu-desktop-xfce/blob/master/troubleshooting/WEB_BROWSERS.md))
```
--shm-size 2g
```

## Magnet links
Firefox in the container's desktop can send the magnet links you click to BiglyBT. \
How to set that up: [MAGNET_LINKS.md](MAGNET_LINKS.md)

## BiglyBT Options
Optional: Choose the version of Java that BiglyBT runs on \
Default: 25
```
-e BBTJAVAVERS='17'
-e BBTJAVAVERS='21'
```
Optional: Run BiglyBT's installer in its window, to choose its options yourself \
Default: automatic quiet install
```
-e BBTGUIINSTALL='1'
```

## The first start
Java and WebKit are in the image. At the container's first login, an xterm window runs ubuntu-desktop-xfce's install_biglybt.sh:
apt-get update (so it needs network access), then BiglyBT's installer from /app/installer. Then BiglyBT starts. \
A `BBTJAVAVERS` other than 25, or `BBTGUIINSTALL`'s Java, is installed with apt-get at that point. \
`docker restart` finds BiglyBT installed. A new container (after `docker rm`) installs it again, and BiglyBT finds its settings,
its torrents and your downloads in /data. \
With a new /data, BiglyBT asks whether to install its Tor Helper Plugin; your answer, with "Don't prompt me again", is kept in /data/config. \
BiglyBT's output goes to /opt/biglybt/biglybt.log.

## Desktop Options
Everything in ubuntu-desktop-xfce's README works the same here: \
[VNC Options](https://github.com/Fullaxx/ubuntu-desktop-xfce#vnc-options) /
[Non-root users](https://github.com/Fullaxx/ubuntu-desktop-xfce#non-root-users) /
[TimeZone](https://github.com/Fullaxx/ubuntu-desktop-xfce#timezone-configuration) /
[Locale](https://github.com/Fullaxx/ubuntu-desktop-xfce#locale-configuration) /
[Input Method](https://github.com/Fullaxx/ubuntu-desktop-xfce#input-method-configuration) /
[Wallpaper](https://github.com/Fullaxx/ubuntu-desktop-xfce#wallpaper-configuration) /
[Extra privileges](https://github.com/Fullaxx/ubuntu-desktop-xfce/blob/master/PRIVILEGES.md) /
[Troubleshooting](https://github.com/Fullaxx/ubuntu-desktop-xfce/tree/master/troubleshooting)

## Run the image
Run the image on localhost port 5901, with your downloads and BiglyBT's settings in /srv/docker/biglybt/data
```
docker run -d -p 127.0.0.1:5901:5901 -p 28474:28474 -p 28474:28474/udp \
-v /srv/docker/biglybt/data:/data ghcr.io/fullaxx/ubuntu-desktop-xfce-biglybt
```
Run the image with a named volume
```
docker volume create biglybt-data
docker run -d -p 127.0.0.1:5901:5901 -p 28474:28474 -p 28474:28474/udp \
-v biglybt-data:/data ghcr.io/fullaxx/ubuntu-desktop-xfce-biglybt
```
Run the image as the built-in ubuntu user account
```
docker run -d -p 127.0.0.1:5901:5901 -p 28474:28474 -p 28474:28474/udp \
-e VNCUSERMAP='ubuntu/1000' \
-v /srv/docker/biglybt/data:/data ghcr.io/fullaxx/ubuntu-desktop-xfce-biglybt
```
Run the image in Denver, with a 1920x1080 desktop and a VNC password
```
docker run -d -p 127.0.0.1:5901:5901 -p 28474:28474 -p 28474:28474/udp \
-e TZ='America/Denver' -e VNCRES='1920x1080' -e VNCPASS='vncpass' \
-v /srv/docker/biglybt/data:/data ghcr.io/fullaxx/ubuntu-desktop-xfce-biglybt
```
Run the image so that it comes back with a fresh desktop after you log out
```
docker run -d --restart unless-stopped -p 127.0.0.1:5901:5901 -p 28474:28474 -p 28474:28474/udp \
-v /srv/docker/biglybt/data:/data ghcr.io/fullaxx/ubuntu-desktop-xfce-biglybt
```

## Connect using vncviewer or a web browser
Use any standard VNC client to connect directly. \
For web access, check out [noVNC](https://github.com/Fullaxx/novnc) to access your container with a web browser.
```
vncviewer 127.0.0.1:5901
```

## How it works
At login, Xfce runs [xfce4/biglybt_autostart.sh](xfce4/biglybt_autostart.sh) (from /etc/xdg/autostart) as the desktop user:
1. It runs [scripts/prepare_biglybt.sh](scripts/prepare_biglybt.sh) as root, through sudo (ubuntu-desktop-xfce's sudo rules allow /app/scripts/prepare_*.sh),
   which makes the five folders, copies the default settings if there are none, and gives a non-root desktop user what's in the folders.
2. It links ~/.biglybt to /data/config, so BiglyBT keeps its settings there.
3. It runs ubuntu-desktop-xfce's /app/scripts/biglybt.sh, which installs BiglyBT the first time, then starts it.

If /data can't be prepared, or the desktop user can't write to one of its folders, a message on the desktop says so. \
After you quit BiglyBT, Applications > Ubuntu Desktop > Network > BitTorrent > BiglyBT starts it again. \
To keep it from starting at login, turn it off in Settings > Session and Startup > Application Autostart.

The default settings, [conf/biglybt.config](conf/biglybt.config), set only these:
| Setting | Value |
| --- | --- |
| Default save path | /data/processing |
| Watch Torrent Folder, and its path | on, /data/autoload |
| Save Torrent Files, in | on, /data/torrents |
| Move Completed When Done, to | on, /data/complete |
| Move Torrent When Done | off (the .torrent stays in /data/torrents) |
| TCP and UDP listen ports | 28474 |

Check the whole path on a Docker host (CI runs this before it publishes)
```
tests/biglybt.sh ghcr.io/fullaxx/ubuntu-desktop-xfce-biglybt
tests/biglybt.sh ghcr.io/fullaxx/ubuntu-desktop-xfce-biglybt -e VNCUSERMAP=ubuntu/1000
```

## Coming from fullaxx/biglybt
- Its two volumes are now folders in /data: /in/autoload is /data/autoload, /in/torrents and /out/torrents are /data/torrents,
  /out/processing is /data/processing and /out/complete is /data/complete.
- OpenVPN is no longer built in, and neither are its options (OVPNCFG, OVPNKS, ...) or the /config mount.
  Run BiglyBT on a VPN container's network instead: [NETWORKING.md](NETWORKING.md)
- Its settings aren't used, and a separate ~/.biglybt volume is no longer needed. Don't copy an old ~/.biglybt into /data/config:
  its settings point at /in and /out, which would then be made inside the container, and lost with it.
  Start with the new settings and add your torrents again.
- VNCUSER/VNCUID were replaced by VNCUSERMAP: [Non-root users](https://github.com/Fullaxx/ubuntu-desktop-xfce#non-root-users)
