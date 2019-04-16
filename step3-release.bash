#!/bin/bash

# -- sane bash errors -- #
set -Eeuo pipefail

# -- resolve symlinks in path -- #

src_dir="${BASH_SOURCE[0]}"
while [ -h "${src_dir}" ]; do
  work_dir="$(cd -P "$(dirname "${src_dir}")" >/dev/null 2>&1 && pwd)"
  src_dir="$(readlink "${src_dir}")"
  [[ ${src_dir} != /* ]] && src_dir="${work_dir}/${src_dir}"
done
work_dir="$(cd -P "$(dirname "${src_dir}")" >/dev/null 2>&1 && pwd)"

cd "${work_dir}"

# -- common code -- #

source ./common.bash

# -- load our docker image -- #

log "load docker image"
pxz -dc "${docker_img_file}" | docker load

# -- write our exec script -- #

cat > node-static-build-script.sh <<EOF
cd /work
cd "${node_src}"
./configure --prefix=/usr --enable-static --partly-static
make -j "\$(nproc)"
DESTDIR="build-partly" make install
./configure --prefix=/usr --enable-static --fully-static
make -j "\$(nproc)"
DESTDIR="build-fully" make install
EOF

# -- execute docker script -- #

log "execute docker build"
docker run --rm -it -v "$(pwd):/work" -u "$(id -u ${USER}):$(id -g ${USER})" "${docker_img}" /bin/sh /work/node-static-build-script.sh

# -- release the bits -- #

log "package release"
cp "${node_src}/build-partly/usr/bin/node" "${node_bin_base}-partly-static"
pxz "${node_bin_base}-partly-static"
release "${node_bin_base}-partly-static.xz"
cp "${node_src}/build-fully/usr/bin/node" "${node_bin_base}-fully-static"
pxz "${node_bin_base}-fully-static"
release "${node_bin_base}-fully-static.xz"
cp -a "${node_src}/build-fully/usr/lib/node_modules/npm" .
tar -I pxz -cf "${node_src}-${build_num}-npm.tar.xz" npm
release "${node_src}-${build_num}-npm.tar.xz"

# -- done -- #
log "done"
