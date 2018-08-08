#!/bin/bash

. ../lib/lib_configure.sh || exit 1

TEMPLATE "geral"
TEMPLATE "graphic_server"
TEMPLATE "display_manager"
TEMPLATE "wm_mate"
TEMPLATE "wm_mate" "set-default"


STEP yum -y install openssh-askpass virt-manager bind-utils

# para VPN
STEP yum -y install autossh sshuttle


