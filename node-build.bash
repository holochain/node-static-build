#!/bin/bash

# -- sane bash errors -- #
set -Eeuo pipefail

# -- variables -- #
BUILD_NUM=alpha7

# TODO - update to node v10 after https://github.com/nodejs/node/issues/23440
NODE_SRC=node-v8.15.1
NODE_SRC_FILE=${NODE_SRC}.tar.gz
NODE_SRC_URL=https://nodejs.org/dist/v8.15.1/$NODE_SRC_FILE
NODE_SRC_HASH=413e0086bd3abde2dfdd3a905c061a6188cc0faceb819768a53ca9c6422418b4

function log() {
  echo "@node-build@ ${@}"
}

# -- download nodejs source -- #
log "DOWNLOAD $NODE_SRC_URL"
curl -L -O $NODE_SRC_URL
echo "$NODE_SRC_HASH  $NODE_SRC_FILE" | sha256sum --check
log "CHECKSUM GOOD"

tar xf $NODE_SRC_FILE

OUT_DIR=./output
mkdir -p $OUT_DIR

function build_with_flags() {
  local __name="$1"
  local __flags="$2"
  local __oname="${NODE_SRC}-linux-${VM_ARCH}-${__name}-${BUILD_NUM}"

  log "Building ${__oname}..."

  log "CONFIGURE-${__name}"
  (cd $NODE_SRC && ./configure --prefix=/usr --enable-static ${__flags})

  log "MAKE-${__name}"
  (cd $NODE_SRC && make -j$(nproc))

  log "MAKE INSTALL-${__name}"
  (cd $NODE_SRC && DESTDIR="build-${__name}" make install)

  log "PACKAGE-${__name}"
  cp $NODE_SRC/build-${__name}/usr/bin/node $OUT_DIR/${__oname}
  (cd $OUT_DIR && sha256sum ${__oname} > ${__oname}.sha256)
  NPM_OUTPUT=npm-$NODE_SRC-$BUILD_NUM.tar.xz
  (cd $NODE_SRC/build-${__name}/usr/lib/node_modules && tar -cJf ../../../../../$OUT_DIR/$NPM_OUTPUT npm)
  (cd $OUT_DIR && sha256sum $NPM_OUTPUT > $NPM_OUTPUT.sha256)
}

build_with_flags "partly" "--partly-static"
build_with_flags "fully" "--fully-static"

log "BUNDLE"
tar -cJf output.tar.xz $OUT_DIR

echo "done."
