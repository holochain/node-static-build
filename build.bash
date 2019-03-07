#!/bin/bash

# -- sane bash errors -- #
set -Eeuo pipefail

# -- variables -- #
BUILD_NUM=alpha5
TOOLCHAIN="${TOOLCHAIN:-linux-x64}"

# TODO - update to node v10 after https://github.com/nodejs/node/issues/23440
NODE_SRC=node-v8.15.1
NODE_SRC_FILE=${NODE_SRC}.tar.gz
NODE_SRC_URL=https://nodejs.org/dist/latest-v8.x/$NODE_SRC_FILE
NODE_SRC_HASH=413e0086bd3abde2dfdd3a905c061a6188cc0faceb819768a53ca9c6422418b4

echo "Building $NODE_SRC-$TOOLCHAIN-$BUILD_NUM..."

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
BUILD_DIR=./build-$TOOLCHAIN
mkdir -p $BUILD_DIR
cd $BUILD_DIR

# -- download nodejs source -- #
if [ ! -f $NODE_SRC_FILE ]; then
  curl -L -O $NODE_SRC_URL
fi
echo "$NODE_SRC_HASH  $NODE_SRC_FILE" | sha256sum --check

# -- setup cross-compiler -- #
TC_BIN=dockcross-$TOOLCHAIN
docker run --rm dockcross/$TOOLCHAIN > ./$TC_BIN
chmod a+x ./$TC_BIN

# -- build node src -- #
if [ ! -f $NODE_SRC/build/usr/bin/node ]; then
  tar xf $NODE_SRC_FILE
  (cd $NODE_SRC && ../$TC_BIN bash -c "./configure --prefix=/usr --enable-static --partly-static" && ../$TC_BIN bash -c "make -j$(nproc)" && ../$TC_BIN bash -c "DESTDIR=build make install")
fi

OUTPUT=$NODE_SRC-$TOOLCHAIN-$BUILD_NUM
cp $NODE_SRC/build/usr/bin/node ../$OUTPUT
(cd .. && sha256sum $OUTPUT > $OUTPUT.sha256)
NPM_OUTPUT=npm-$NODE_SRC-$BUILD_NUM.tar.xz
(cd $NODE_SRC/build/usr/lib/node_modules && tar -cJf ../../../../../../$NPM_OUTPUT npm)
(cd .. && sha256sum $NPM_OUTPUT > $NPM_OUTPUT.sha256)

echo "done."
