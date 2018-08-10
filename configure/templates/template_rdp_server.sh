#!/bin/bash

. ../lib/lib_configure.sh || exit

GROUP "Dependências"
STEP  yum -y install epel-release

### Minimal X Window System + Fonts
GROUP "Minimal X Window System"
STEP  yum -y groupinstall "X Window System" "Fonts"

GROUP "XRDP"
STEP  yum -y install xrdp
STEPI "Ajustando teclado ABNT2 para xrdp"  cp -f "${DIR_EXTRA_FILES}/km-00010416.ini" /etc/xrdp/km-00010416.ini
STEP  systemctl enable xrdp
STEP  systemctl start  xrdp

INFO "Para poder usar, é necessário instalar pelo menos um Window Manager (scripts configure_wm_*)"

