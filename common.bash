#!/bin/bash

build_num=alpha8

# -- sane bash errors -- #

set -Eeuo pipefail

# -- functions -- #

function log() {
  echo "**node-static-build** ${@}"
}

function dl() {
  local __url="${1}"
  local __file="${2}"
  local __hash="${3}"
  if [ ! -f "${__file}" ]; then
    curl -L -O "${__url}"
  fi
  log "${__file} hashes to $(sha256sum ${__file})"
  echo "${__hash}  ${__file}" | sha256sum --check
}

function dl_artifact() {
  local __file="${1}"
  if [ ! -f "${__file}" ]; then
    if [ "x${TRAVIS_TAG}" == "x" ]; then
      log "ERROR, cannot download an artifact when not running on travis"
      exit 1
    fi
    curl -L -O "https://github.com/holochain/node-static-build/releases/download/${TRAVIS_TAG}/${__file}"
  fi
}

# -- resolve environment -- #

this_arch="$(uname -m)"

qemu_url=""
qemu_file=""
qemu_hash=""

case "${this_arch}" in
  "x86_64")
    qemu_url="http://ftp.us.debian.org/debian/pool/main/q/qemu/qemu-user-static_3.1+dfsg-7_amd64.deb"
    qemu_file="qemu-user-static_3.1+dfsg-7_amd64.deb"
    qemu_hash="0699a74d9eb7cb4b68d500a2788e699ee98964460e5d10020619014135527d76"
    ;;
  *)
    log "ERROR, unsupported host arch ${this_arch}, supported hosts: x86_64"
    exit 1
    ;;
esac

tgt_arch="${TGT_ARCH:-unset}"

qemu_bin=""
docker_from=""

case "${tgt_arch}" in
  "x64")
    qemu_bin="qemu-x86_64-static"
    docker_from="amd64/debian:stretch-slim"
    ;;
  "ia32")
    qemu_bin="qemu-i386-static"
    docker_from="i386/debian:stretch-slim"
    ;;
  "armv7l")
    qemu_bin="qemu-arm-static"
    docker_from="arm32v7/debian:stretch-slim"
    ;;
  "arm64")
    qemu_bin="qemu-aarch64-static"
    docker_from="arm64v8/debian:stretch-slim"
    ;;
  *)
    log "ERROR, unsupported target arch ${tgt_arch}, supported targets: x64, ia32, armv7l, arm64"
    exit 1
    ;;
esac

docker_img="node-static-build-docker-${tgt_arch}"
docker_img_file="node-static-build-docker-${tgt_arch}.tar.xz"

# TODO - update to node v10 after https://github.com/nodejs/node/issues/23440
node_src="node-v8.15.1"
node_src_file="${node_src}.tar.gz"
node_src_url="https://nodejs.org/dist/v8.15.1/${node_src_file}"
node_src_hash="413e0086bd3abde2dfdd3a905c061a6188cc0faceb819768a53ca9c6422418b4"
node_bin_base="${node_src}-${build_num}-linux-${tgt_arch}"

# -- setup build directory -- #

work_dir="$(pwd)/build/build-${tgt_arch}"
mkdir -p "${work_dir}"
cd "${work_dir}"

out_dir="$(pwd)/output"
mkdir -p "${out_dir}"

# -- release function -- #

function release() {
  __path="${1}"
  __file="$(basename "${__path}")"
  cp -af "${__path}" "${out_dir}/${__file}"
  (cd "${out_dir}" && sha256sum "${__file}" > "${__file}.sha256")
}
