#!/bin/bash

. ../lib/lib_configure.sh || exit 1

# Bug de delay de 30s quando initram não encontra o swap block device
ADD_LINE /etc/initramfs-tools/conf.d/resume "RESUME=none" "^RESUME="

