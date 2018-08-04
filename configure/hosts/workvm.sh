#!/bin/bash

. ../lib/lib_configure.sh || exit 1

TEMPLATE "geral"
TEMPLATE "graphic_server"
TEMPLATE "display_manager"
TEMPLATE "wm_mate"
TEMPLATE "wm_mate" "set-default"

# STEP yum -y install git vim mc "bash-completion*"

