#!/bin/bash


. ../lib/lib_configure.sh || exit 1


STEP apt-get -y install vim mc git colordiff "bash-completion*"
STEP apt-get -y install seahorse openssh-server chromium-browser sublime-text

STEP systemctl enable ssh
STEP systemctl start  ssh

STEP apt-get -y remove "openjdk-11-jre*"
STEP apt-get -y install openjdk-8-jdk maven gradle
STEP apt-get -y upgrade "ca-certificates*"

STEP apt-get -y install mate-themes

TEMPLATE install_sts

STEP apt-get -y install docker.io docker-compose

STEP update-alternatives --set editor /usr/bin/vim.basic

