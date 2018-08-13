#!/bin/bash

. ../lib/lib_configure.sh || exit 1

GROUP "Dependências"
STEP  yum -y install epel-release

### Minimal X Window System + Fonts
GROUP "Minimal X Window System"
STEP  yum -y groupinstall "X Window System" "Fonts"

INFO "Para poder usar, é necessário instalar pelo menos um Window Manager (scripts *_desktop)"

