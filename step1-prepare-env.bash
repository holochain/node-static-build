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

# -- get more recent qemu-use-static binaries -- #

log "download qemu-user-static"
dl "${qemu_url}" "${qemu_file}" "${qemu_hash}"

log "extract debian archive"
( \
  mkdir -p ./qemu && \
  cd ./qemu && \
  ar x "../${qemu_file}" && \
  tar xf data.tar.xz \
)

# -- build docker image -- #

cat > Dockerfile <<EOF
FROM ${docker_from}

COPY ./qemu/usr/bin/${qemu_bin} /usr/bin/${qemu_bin}

RUN apt-get update && apt-get install -y --no-install-recommends \
  autoconf automake make \
  g++ gcc python && \
  rm -rf /var/lib/apt/lists/*
EOF

log "build docker image"
docker build -t "${docker_img}" .

log "compressing docker image"
docker save "${docker_img}" | pxz -zT 0 > "${docker_img_file}"

# -- download node src -- #

log "download nodejs source"
dl "${node_src_url}" "${node_src_file}" "${node_src_hash}"
tar xf "${node_src_file}"

# -- write our exec script -- #

cat > node-static-build-script.sh <<EOF
cd /work
cd "${node_src}"
./configure --prefix=/usr --enable-static --partly-static
EOF

# -- execute docker script -- #

log "execute docker build"
docker run --rm -it -v "$(pwd):/work" -u "$(id -u ${USER}):$(id -g ${USER})" "${docker_img}" /bin/sh /work/node-static-build-script.sh

# -- done -- #
log "done"
