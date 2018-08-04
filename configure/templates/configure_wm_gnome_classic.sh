#!/bin/bash

. ../lib/lib_configure.sh

case "$CONFTARGET" in

	install)

		GROUP "Dependências"
		STEP  yum -y install epel-release

		GROUP "GNOME Classic Desktop"
		STEP  yum -y install gnome-classic-session gnome-terminal nautilus-open-terminal control-center xterm
		RUN   touch /etc/sysconfig/desktop
		;;

	set-default)
      WM_SET_DEFAULT "gnome-classic"
		;;

esac

INFO "Dica: para usar o Gnome Classic, edite o arquivo /etc/sysconfig/desktop ou informe o parâmetro set-default"

