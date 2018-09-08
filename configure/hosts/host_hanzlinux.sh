#!/bin/bash


. ../lib/lib_configure.sh || exit 1


TEMPLATE basic_desktop
TEMPLATE bug_disable_resume
TEMPLATE ssh_server

STEP apt-get -y remove "openjdk-11-jre*"
STEP apt-get -y install openjdk-8-jdk maven gradle
STEP apt-get -y install "ca-certificates*"

STEP apt-get -y install docker.io docker-compose

TEMPLATE install_sts
TEMPLATE virt_server

