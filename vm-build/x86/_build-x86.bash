#!/bin/bash

# -- sane bash errors -- #
set -xEeuo pipefail

CLEANUP_PAUSE=${CLEANUP_PAUSE:-0}
echo "==> Pausing for ${CLEANUP_PAUSE} seconds..."
sleep ${CLEANUP_PAUSE}

echo "==> Add Swap"
dd if=/dev/zero of=/swapfile bs=4096 count=262144
sudo chmod 600 /swapfile
mkswap /swapfile
echo '/swapfile swap swap defaults 0 0' >> /etc/fstab

echo "==> Build Packages"
apt-get -y update

apt-get install -y \
  sudo \
  vim \
  htop \
  curl \
  wget \
  git \
  autoconf \
  automake \
  gnupg2 \
  file \
  fuse \
  libfuse-dev \
  desktop-file-utils \
  g++ \
  gcc \
  libbz2-dev \
  libc6-dev \
  libglib2.0-dev \
  libgmp-dev \
  liblzma-dev \
  libncurses5-dev \
  libncursesw5-dev \
  libpng12-dev \
  libreadline-dev \
  libsqlite3-dev \
  libtool \
  make \
  patch \
  unzip \
  xz-utils \
  zlib1g-dev \
  node-gyp

echo "==> Configure Grub / Kernel for Serial Output"
sed -i.bak '/^GRUB_\(CMDLINE\|TIMEOUT\|TERMINAL\|SERIAL\)/d' /etc/default/grub
echo 'GRUB_TIMEOUT=1
GRUB_CMDLINE_LINUX_DEFAULT=""
GRUB_CMDLINE_LINUX="console=tty1 console=ttyS0,115200"
GRUB_TERMINAL="console serial"
GRUB_SERIAL_COMMAND="serial --speed=115200 --unit=0 --word=8 --parity=no --stop=1"
' >> /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg

echo "==> Configure Sudo / SSH"
mkdir -p /etc/sudoers.d
echo 'node-static-build ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/node-static-build
echo 'AuthorizedKeysFile .ssh/authorized_keys' >> /etc/ssh/sshd_config
mkdir -p /home/node-static-build/.ssh
echo 'ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA6NF8iallvQVp22WDkTkyrtvp9eWW6A8YVr+kz4TjGYe7gHzIw+niNltGEFHzD8+v1I2YJ6oXevct1YeS0o9HZyN1Q9qgCgzUFtdOKLv6IedplqoPkcmF0aYet2PkEDo3MlTBckFXPITAMzF8dJSIFo9D8HfdOV0IAdx4O7PtixWKn5y2hMNG0zQPyUecp4pzC6kivAIhyfHilFR61RGL+GPXQ2MWZWFYbAGjyiYJnAmCP3NOTd0jMZEnDkbUvxhMmBYSdETk1rRgm+R4LOzFUGaHqHDLKLX+FIPKcF96hrucXzcWyLbIbEgE98OHlnVYCzRdK8jlqm8tehUc9c9WhQ== insecure-key' > /home/node-static-build/.ssh/authorized_keys
chown 1000:1000 /home/node-static-build/.ssh/authorized_keys

echo "==> Additional System Config"
echo 'login with user `node-static-build` password `node-static-build`
this user should have passwordless sudo permissions

#node-static-build#-BOOT-COMPLETE-#

' >> /etc/issue

echo "==> Cleanup"
rm -rf /dev/.udev/
rm /lib/udev/rules.d/75-persistent-net-generator.rules
if [ -d "/var/lib/dhcp" ]; then
    rm /var/lib/dhcp/*
fi
apt-get -y autoremove --purge
apt-get -y clean
apt-get -y autoclean
rm -rf /usr/share/man/??
rm -rf /usr/share/man/??_*
rm -rf /tmp/*
find /var/log -type f | while read f; do echo -ne '' > $f; done;
unset HISTFILE
rm -f /root/.bash_history
