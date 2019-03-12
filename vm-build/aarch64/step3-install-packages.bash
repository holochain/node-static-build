#!/bin/bash

# -- sane bash errors -- #
set -Eeuo pipefail

export VM_IMAGE_DIR=./image
export VM_USER=root
export VM_IN_PLACE=1
../../vm-exec.bash ./_step3-install-packages-guest.bash
