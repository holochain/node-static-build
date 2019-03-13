#!/bin/bash

# -- sane bash errors -- #
set -Eeuo pipefail

apt-get -y update
apt-get install -y \
  sudo \
  vim \
  htop \
  curl \
  wget \
  git \
  autoconf \
  automake \
  gnupg \
  file \
  fuse \
  libfuse-dev \
  desktop-file-utils \
  appstream \
  g++ \
  gcc \
  libbz2-dev \
  libc6-dev \
  libglib2.0-dev \
  libgmp-dev \
  liblzma-dev \
  libncurses5-dev \
  libncursesw5-dev \
  libpng-dev \
  libreadline-dev \
  libsqlite3-dev \
  libtool \
  make \
  patch \
  unzip \
  xz-utils \
  zlib1g-dev \
  node-gyp
