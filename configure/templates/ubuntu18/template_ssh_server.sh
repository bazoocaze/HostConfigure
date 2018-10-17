#!/bin/bash

. ../lib/lib_configure.sh || exit 1

STEP apt-get -y install openssh-server
STEP systemctl enable ssh
STEP systemctl start  ssh

#RUN ufw allow 22

