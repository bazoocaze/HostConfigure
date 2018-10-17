#!/bin/bash

. ../lib/lib_configure.sh || exit 1

TEMPLATE basic_mate_desktop
TEMPLATE ssh_server
TEMPLATE ssh_keys
TEMPLATE virt_server

STEP apt-get -y install mysql-client


