#!/bin/bash

# -- sane bash errors -- #
set -Eeuo pipefail

# -- cd -- #
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do
  DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"

cd $DIR

BUILD_DIR=./image

SCRIPT="echo 'sudo start'
set -Eeuo pipefail
mkdir mnt
#guestmount -a $BUILD_DIR/machine.qcow2 -m /dev/sda1 ./mnt
#cp mnt/initrd.img*arm64 $BUILD_DIR/initrd
#cp mnt/vmlinuz*arm64 $BUILD_DIR/vmlinuz
#guestunmount mnt
guestmount -a $BUILD_DIR/machine.qcow2 -m /dev/sda2 ./mnt
mkdir -p ./mnt/etc/sudoers.d
echo 'node-static-build ALL=(ALL) NOPASSWD: ALL' > ./mnt/etc/sudoers.d/node-static-build
echo 'AuthorizedKeysFile .ssh/authorized_keys' >> ./mnt/etc/ssh/sshd_config
mkdir -p ./mnt/home/node-static-build/.ssh
echo 'ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA6NF8iallvQVp22WDkTkyrtvp9eWW6A8YVr+kz4TjGYe7gHzIw+niNltGEFHzD8+v1I2YJ6oXevct1YeS0o9HZyN1Q9qgCgzUFtdOKLv6IedplqoPkcmF0aYet2PkEDo3MlTBckFXPITAMzF8dJSIFo9D8HfdOV0IAdx4O7PtixWKn5y2hMNG0zQPyUecp4pzC6kivAIhyfHilFR61RGL+GPXQ2MWZWFYbAGjyiYJnAmCP3NOTd0jMZEnDkbUvxhMmBYSdETk1rRgm+R4LOzFUGaHqHDLKLX+FIPKcF96hrucXzcWyLbIbEgE98OHlnVYCzRdK8jlqm8tehUc9c9WhQ== insecure-key' > ./mnt/home/node-static-build/.ssh/authorized_keys
guestunmount mnt
echo 'sudo done'"

function cleanup() {
  sudo bash -c "if [ \$(ls mnt | wc -l) -ne 0 ]; then guestunmount mnt || true; fi" || true
  sudo bash -c "rm -rf mnt" || true
  echo "done."
}
trap cleanup EXIT

sudo bash -c "$SCRIPT"
