# ------------------------------------------------------------------------------
# Base Image : ghcr.io/fullaxx/ubuntu-desktop-xfce:26.04 (https://github.com/Fullaxx/ubuntu-desktop-xfce)
#              Ubuntu 26.04 LTS (Resolute Raccoon), Xfce 4.20, TigerVNC 1.15
# Support    : Apr 2026 - May 2031
FROM ghcr.io/fullaxx/ubuntu-desktop-xfce:26.04
LABEL author="Brett Kuskie <fullaxx@gmail.com>"

# ------------------------------------------------------------------------------
# Install tools and clean up
# (7zip-rar comes from multiverse, which the base image's apt sources include)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      7zip \
      7zip-rar \
      bash-completion \
      buildtorrent \
      bzip2 \
      ca-certificates \
      curl \
      file \
      iproute2 \
      iputils-ping \
      lsof \
      mktorrent \
      mtr-tiny \
      net-tools \
      openjdk-25-jre-headless \
      openssh-client \
      tree \
      unzip \
      webkitgtk-webdriver \
      wget \
      xz-utils \
      zip \
      zstd && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /var/tmp/* /tmp/*

# ------------------------------------------------------------------------------
# Download the latest BiglyBT installer
# (the base image's /app/scripts/install_biglybt.sh installs it at the first start instead of downloading one;
# ADD checks the URL again at every build, so a rebuild picks up a new BiglyBT release, where RUN wget would stay cached)
ADD --chmod=0755 https://files.biglybt.com/installer/BiglyBT_Installer.sh /app/installer/

# ------------------------------------------------------------------------------
# Provide default BiglyBT config
# (/app/scripts/prepare_biglybt.sh copies it to /data/config when BiglyBT has no config there yet)
COPY conf/biglybt.config /usr/share/biglybt/biglybt.config.default

# ------------------------------------------------------------------------------
# Install scripts and configuration files
# (the desktop user runs prepare_biglybt.sh through sudo: the base image's sudo rules allow /app/scripts/prepare_*.sh)
COPY scripts/prepare_biglybt.sh /app/scripts/
# Xfce starts BiglyBT at login (/etc/xdg/autostart is only for .desktop files, the scripts go on PATH)
COPY xfce4/biglybt_autostart.sh /usr/local/bin/
COPY xfce4/biglybt_autostart.desktop /etc/xdg/autostart/

# ------------------------------------------------------------------------------
# Identify Volumes
VOLUME /data

# ------------------------------------------------------------------------------
# Expose ports
# (BiglyBT's listen port, from the default config; the base image exposes VNC's 5901)
EXPOSE 28474/tcp 28474/udp

# ------------------------------------------------------------------------------
# Define default command
# (ubuntu-desktop-xfce's startup, unchanged)
CMD ["/app/app.sh"]
