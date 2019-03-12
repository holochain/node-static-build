#!/bin/bash

# -- sane bash errors -- #
set -Eeuo pipefail

(cd image && tar -I pxz -cf ../node-static-build-vm-aarch64.tar.xz initrd linux machine.qcow2)
