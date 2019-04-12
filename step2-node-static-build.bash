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

# -- get our docker image -- #

dl_artifact "${docker_img_file}"

# -- download node src -- #

dl "${node_src_url}" "${node_src_file}" "${node_src_hash}"
tar xf "${node_src_file}"

if [[ -f touch_order.txt ]]; then
  log "sorting file times to continue build"
  while read fn; do
    touch "${fn}"
  done < touch_order.txt
fi

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

# -- load our docker image -- #

log "load docker image"
pxz -dc "${docker_img_file}" | docker load

# -- execute docker script -- #

log "execute docker build"
if [ -z ${CI_RUN_MIN+x} ]; then
  log "running complete script"
  docker run --rm -it -v "$(pwd):/work" -u "$(id -u ${USER}):$(id -g ${USER})" "${docker_img}" /bin/sh /work/node-static-build-script.sh
else
  log "running script with CI_RUN_MIN: ${CI_RUN_MIN-40}m"
  docker run --rm -it -v "$(pwd):/work" -u "$(id -u ${USER}):$(id -g ${USER})" "${docker_img}" /bin/sh -c "timeout ${CI_RUN_MIN-40}m /bin/sh /work/node-static-build-script.sh" || true
fi

# -- release the bits -- #

if [ -z ${CI_RUN_MIN+x} ]; then
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
else
  log "not releasing, CI_RUN_MIN was set: ${CI_RUN_MIN-}m"
fi

find . -type f -printf "%T+\t%p\n" | sort | cut -f 2 > touch_order.txt

# -- done -- #
log "done"
