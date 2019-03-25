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

PACKER_URL="https://releases.hashicorp.com/packer/1.3.5/packer_1.3.5_linux_amd64.zip"
PACKER_FILE="packer_1.3.5_linux_amd64.zip"
PACKER_HASH="14922d2bca532ad6ee8e936d5ad0788eba96f773bcdcde8c2dc7c95f830841ec"

DEB_URL="https://cdimage.debian.org/cdimage/archive/8.11.1/armhf/iso-cd/debian-8.11.1-armhf-netinst.iso"
DEB_FILE="debian-8.11.1-armhf-netinst.iso"
DEB_HASH="69216508fa2e3b184fd41f354c2efcc8f0c02dbe2e90bb23a69c316267f56283"

# -- cd -- #
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do
  DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"

cd $DIR

BUILD_DIR=./packer_cache
mkdir -p "$BUILD_DIR"

(cd "$BUILD_DIR" && dl "$PACKER_URL" "$PACKER_FILE" "$PACKER_HASH")
(cd "$BUILD_DIR" && unzip -f "$PACKER_FILE")
(cd "$BUILD_DIR" && dl "$DEB_URL" "$DEB_FILE" "$DEB_HASH")

PACKER_LOG="yes" PACKER_LOG_PATH="$BUILD_DIR/packer.log" $BUILD_DIR/packer build packer-armv7.json
