#!/bin/bash

# -- sane bash errors -- #
set -Eeuo pipefail

VM_ARCH=${VM_ARCH:-unset}
if [ "$VM_ARCH" == "unset" ]; then
  VM_ARCH=$(uname -m)
  if [ "$VM_ARCH" == "x86_64" ]; then
    VM_ARCH="x64"
  fi
fi

function log() {
  echo "**node-static-build** ${@}"
}

# -- resolve symlinks in path -- #
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do
  DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"

cd $DIR

DIST_DIR=./dist

# -- setup build directory -- #
mkdir -p $DIST_DIR
cd $DIST_DIR
BUILD_DIR=./build-$VM_ARCH
mkdir -p $BUILD_DIR
cd $BUILD_DIR

log "Building $VM_ARCH into $DIST_DIR/$BUILD_DIR"

TC_BIN=""
function exec_dockcross() {
  TC_BIN="dockcross-$VM_ARCH"
  docker run --rm dockcross/linux-$VM_ARCH > ./$TC_BIN
  chmod a+x ./$TC_BIN
  cp ../../node-build.bash .
  ./$TC_BIN bash -c "VM_ARCH=$VM_ARCH ./node-build.bash"
}

case "${VM_ARCH}" in
  "x86")
    exec_dockcross
    ;;
  "x64")
    exec_dockcross
    ;;
  "aarch64")
    VM_ARCH=$VM_ARCH ../../vm-exec.bash ../../node-build.bash
    ;;
  *)
    log "ERROR, bad VM_ARCH: $VM_ARCH"
    exit 1
    ;;
esac

rm -rf output

tar xf output.tar.xz

echo "done."
