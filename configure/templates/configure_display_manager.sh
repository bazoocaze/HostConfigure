#!/bin/bash

. ../lib/lib_configure.sh || exit 1


case "$CONFTARGET" in

	install)

		STEP yum -y install epel-release
		STEP yum -y install lightdm

		STEP systemctl set-default graphical.target
		STEP systemctl enable lightdm
		;;

	undo)

		STEP systemctl disable lightdm
		STEP systemctl set-default multi-user.target
		;;

esac

