#!/bin/bash

YUMREPOS="/etc/yum.repos.d"
WEBMINREPO="${YUMREPOS}/webmin.repo"

. ../lib/lib_configure.sh || exit 1


#----------------------------------------------------------------------
install_webmin()
{
if [ -f "$WEBMINREPO" ] ; then
	if EXEC rpm -q "webmin" ; then
		OK "Webmin está instalado"
		return 0
	fi
fi

[ ! -d "$YUMREPOS" ] && DIE "Diretório não encontrado: $YUMREPOS"

STEP                                    yum -y install curl perl-IO-Pty-Easy
STEPI "Baixando chave jcameron-key.asc" curl -f 'http://www.webmin.com/jcameron-key.asc' -o "/tmp/jcameron-key.asc"
STEPI "Importando chave"                rpm --import "/tmp/jcameron-key.asc"
STEP                                    cp -f "${DIR_EXTRA_FILES}/webmin.repo" "$WEBMINREPO"
STEP                                    yum -y install webmin
}


#----------------------------------------------------------------------


install_webmin

STEP augtool set '/files/etc/webmin/miniserv.conf/sudo' 1
STEP augtool set '/files/etc/webmin/miniserv.conf/unixauth' '@wheel=root'
STEP systemctl daemon-reload
RUN  /etc/webmin/stop
STEP systemctl enable  webmin
STEP systemctl restart webmin

