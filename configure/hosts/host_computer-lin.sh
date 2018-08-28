#!/bin/bash


. ../lib/lib_configure.sh || exit 1


STEP apt-get -y install vim mc git colordiff "bash-completion*"
STEP apt-get -y install seahorse openssh-server chromium-browser sublime-text
STEP apt-get -y install mate-themes
STEP apt-get -y install "ca-certificates"
STEP update-alternatives --set editor /usr/bin/vim.basic

# Bug de delay de 30s quando initram não encontra o swap block device
ADD_LINE /etc/initramfs-tools/conf.d/resume "RESUME=none" "^RESUME="

TEMPLATE ssh_server

# STEP apt-get -y remove "openjdk-11-jre*"
# STEP apt-get -y install openjdk-8-jdk maven gradle
# TEMPLATE install_sts

# STEP apt-get -y install docker.io docker-compose

# TEMPLATE virt_server

