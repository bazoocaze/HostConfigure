#!/bin/bash

. ../lib/lib_configure.sh || exit 1


TEMPLATE basic_workstation
TEMPLATE ssh_keys
TEMPLATE virt_guest
TEMPLATE graphic_server
TEMPLATE display_manager
TEMPLATE mate_desktop
TEMPLATE mate_desktop set-default

