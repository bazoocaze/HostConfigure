#!/bin/bash

. ../lib/lib_configure.sh || exit 1


ADD_NSSCONF()
{
local entry="$1"
local lib="$2"
local after="$3"
local conf="/etc/nsswitch.conf"

	[ -z "$1" -o -z "$2" -o -z "$3" ] && ASSERT "ADD_NSSCONF($1, $2, $3): parâmetros inválidos"

	ITEM "Atualizando arquivo ${conf} com ${entry}: ${lib}"

	if ! grep -q "^${entry}:" "${conf}" ; then
		DIE "${conf}: entrada '${entry}:' não encontrada"
	fi

	if grep "^${entry}:" "${conf}" | grep -q "${lib}" ; then
		OK "${conf}: nenhuma alteração necessária"
		return 0
	fi

	if ! grep "^${entry}:" "${conf}" | grep -q "${after}" ; then
		DIE "${conf}: entrada '${entry}: ${after}' não encontrada"
	fi

	EXEC cp -f "${conf}" "${conf}.bak" || DIE "Impossível fazer backup do arquivo ${conf}"

	EXEC sed -i "/^${entry}:/s/${after}/${after} ${lib}/g;" "${conf}"	|| DIE "Não foi possível atualizar o arquivo ${conf}"

	OK "Arquivo ${conf} atualizado com sucesso"
}


GROUP "Firewall"
STEP systemctl stop    ufw
STEP systemctl disable ufw

STEP apt-get -y install firewalld ebtables ipset firewalld

STEP systemctl enable firewalld
STEP systemctl start  firewalld


GROUP "QEMU / LibVirt"
STEP apt-get -y install qemu-utils qemu-kvm
STEP apt-get -y install libvirt-daemon libvirt-clients libvirt-daemon-system libnss-libvirt
STEP apt-get -y install virt-manager spice-client-gtk gir1.2-spiceclientgtk-3.0

ADD_NSSCONF "hosts" "libvirt" "files"

