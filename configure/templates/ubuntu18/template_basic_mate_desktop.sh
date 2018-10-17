#!/bin/bash

. ../lib/lib_configure.sh || exit 1

STEP apt-get -y install vim mc git colordiff "bash-completion*"
STEP apt-get -y install seahorse chromium-browser krdc
STEP apt-get -y install mate-themes
STEP update-alternatives --set editor /usr/bin/vim.basic

