#!/bin/bash

# -- sane bash errors -- #
set -Eeuo pipefail

# -- variables -- #
BUILD_NUM=alpha6

# TODO - update to node v10 after https://github.com/nodejs/node/issues/23440
NODE_SRC=node-v8.15.1
NODE_SRC_FILE=${NODE_SRC}.tar.gz
NODE_SRC_URL=https://nodejs.org/dist/v8.15.1/$NODE_SRC_FILE
NODE_SRC_HASH=413e0086bd3abde2dfdd3a905c061a6188cc0faceb819768a53ca9c6422418b4

function log() {
  echo "@node-build@ ${@}"
}

ONAME=$NODE_SRC-linux-$VM_ARCH-$BUILD_NUM
log "Building $ONAME..."

OUT_DIR=./output
mkdir -p $OUT_DIR

# -- download nodejs source -- #
log "DOWNLOAD $NODE_SRC_URL"
curl -L -O $NODE_SRC_URL
echo "$NODE_SRC_HASH  $NODE_SRC_FILE" | sha256sum --check
log "CHECKSUM GOOD"

tar xf $NODE_SRC_FILE

log "CONFIGURE"
(cd $NODE_SRC && ./configure --prefix=/usr --enable-static --partly-static)

log "MAKE"
(cd $NODE_SRC && make -j$(nproc))

log "MAKE INSTALL"
(cd $NODE_SRC && DESTDIR=build make install)

log "PACKAGE"
cp $NODE_SRC/build/usr/bin/node $OUT_DIR/$ONAME
(cd $OUT_DIR && sha256sum $ONAME > $ONAME.sha256)
NPM_OUTPUT=npm-$NODE_SRC-$BUILD_NUM.tar.xz
(cd $NODE_SRC/build/usr/lib/node_modules && tar -cJf ../../../../../$OUT_DIR/$NPM_OUTPUT npm)
(cd $OUT_DIR && sha256sum $NPM_OUTPUT > $NPM_OUTPUT.sha256)

log "BUNDLE"
tar -cJf output.tar.xz $OUT_DIR

echo "done."
