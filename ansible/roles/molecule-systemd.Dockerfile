FROM debian:trixie

# Install systemd and clean up
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      systemd systemd-sysv python3 python3-apt sudo \
      dbus && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Remove unnecessary systemd units that cause issues in containers
RUN rm -f /lib/systemd/system/multi-user.target.wants/* \
    /etc/systemd/system/*.wants/* \
    /lib/systemd/system/local-fs.target.wants/* \
    /lib/systemd/system/sockets.target.wants/*udev* \
    /lib/systemd/system/sockets.target.wants/*initctl* \
    /lib/systemd/system/sysinit.target.wants/systemd-tmpfiles-setup* \
    /lib/systemd/system/systemd-update-utmp*

VOLUME ["/sys/fs/cgroup", "/run", "/run/lock"]
CMD ["/lib/systemd/systemd"]
