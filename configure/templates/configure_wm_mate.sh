#!/bin/bash


. ../lib/lib_configure.sh || exit 1


case "$CONFTARGET" in
	install)
		GROUP "Dependências"
		STEP  yum -y install epel-release augeas

		GROUP "MATE Desktop"
		STEP  yum -y install mate-desktop "mate-*daemon" "mate-icon*" "mate-theme*" mate-terminal xterm caja "gnome-keyring*" mate-power-manager
		STEP  yum -y install pluma evince seahorse
		RUN   touch /etc/sysconfig/desktop
		;;

	set-default)
		WM_SET_DEFAULT "/usr/bin/mate-session"
		;;

esac

INFO "Dica: para usar o Mate Desktop, inclua PREFERRED=mate-session no arquivo /etc/sysconfig/desktop ou informe o parâmetro set-default"

OK "Concluído"

