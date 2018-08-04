#!/bin/bash

. ../lib/lib_configure.sh || exit 1

case "$CONFTARGET" in
	install)

		GROUP "Dependências"
		STEP yum -y install epel-release

		GROUP "OpenBox Desktop"
		STEP yum -y install openbox polkit-gnome xterm
		ADD_LINE /etc/xdg/openbox/autostart \
			"sleep 1 && /usr/libexec/polkit-gnome-authentication-agent-1 &" \
			"polkit-gnome-authentication-agent-1"

		RUN touch /etc/sysconfig/desktop
		;;

	set-default)
		WM_SET_DEFAULT "/usr/bin/openbox-session" 
		;;

esac

INFO "Dica: para usar o OpenBox, edite o arquivo /etc/sysconfig/desktop ou informe o parâmetro set-default"

OK "Concluído"

