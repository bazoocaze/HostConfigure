#!/bin/bash

. lib_configure.sh

STEP systemctl stop firewalld
STEP systemctl disable firewalld

STEP yum -y install deltarpm
STEP yum -y install epel-release
STEP yum -y install mc git vim "bash-completion*" net-tools augeas
STEP yum -y install gnome-software

STEP plymouth-set-default-theme details
STEP augtool 'set /files/etc/sysconfig/selinux/SELINUX permissive'

STEP yum -y groupinstall "X Window System" "Fonts"

STEP yum -y install caja mate-desktop "mate-icon*" "mate-theme*" "mate-*daemon" mate-terminal "gnome-keyring*" "mate-power*"
STEP yum -y install pluma seahorse chromium
STEP augtool '
	set /files/etc/sysconfig/desktop/DESKTOP ""
	set /files/etc/sysconfig/desktop/PREFERRED "mate-session"'

STEP yum -y install lightdm
STEP systemctl enable lightdm
STEP systemctl set-default graphical.target

STEP mkdir -p /dados/apps
STEP mkdir -p /dados/temp
STEP chmod 777 /dados
STEP chmod 777 /dados/temp
STEP chmod 777 /dados/apps

OK "Concluído!"
