#!/bin/bash

# -- sane bash errors -- #
set -Eeuo pipefail

function dl {
  local __url="${1}"
  local __file="${2}"
  local __hash="${3}"
  if [ ! -f "${__file}" ]; then
    curl -L -O "${__url}"
  fi
  echo "${__hash}  ${__file}" | sha256sum --check
}

INITRD_URL=http://ftp.debian.org/debian/dists/Debian9.8/main/installer-arm64/20170615+deb9u5+b2/images/netboot/debian-installer/arm64/initrd.gz
INITRD_FILE=initrd.gz
INITRD_HASH=b2cd7f1f49eb1f13a63f1ff671acf97f9bbd298d2b57dd9b2c322b37b1f2cb47

LINUX_URL=http://ftp.debian.org/debian/dists/Debian9.8/main/installer-arm64/20170615+deb9u5+b2/images/netboot/debian-installer/arm64/linux
LINUX_FILE=linux
LINUX_HASH=07c12a7a2174955c4569a8887785f72f40fbb97a42c98d8040e3bb96efefbcb3

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
mkdir -p $BUILD_DIR

dl $INITRD_URL $INITRD_FILE $INITRD_HASH
dl $LINUX_URL $LINUX_FILE $LINUX_HASH

# -- build disk image -- #
qemu-img create -f qcow2 $BUILD_DIR/machine.qcow2 10G

# -- boot the image -- #
CMD="qemu-system-aarch64 -M virt -cpu cortex-a57 -m 4G
    -initrd $INITRD_FILE
    -kernel $LINUX_FILE
    -append \"root=/dev/sda2 console=ttyAMA0\"
    -global virtio-blk-device.scsi=off
    -device virtio-scsi-device,id=scsi
    -drive file=$BUILD_DIR/machine.qcow2,id=rootimg,cache=unsafe,if=none
    -device scsi-hd,drive=rootimg
    -device virtio-net-device,netdev=unet
    -netdev user,id=unet,hostfwd=tcp::2222-:22
    -nographic
    -monitor telnet::45454,server,nowait
    -serial mon:stdio"
echo $CMD
eval $CMD
