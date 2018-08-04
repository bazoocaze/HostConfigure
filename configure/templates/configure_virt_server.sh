#!/bin/bash

. ../lib/lib_configure.sh || exit 1


virsh_create_pool_dir()
{
local nome="$1"
local dir="$2"
	STEP mkdir -p "$dir"
	STEPI "Criando storage-pool $nome para libvirt" virsh pool-define-as --name "$nome" --type dir --target "$dir"
	STEP virsh pool-autostart "$nome"
	STEP virsh pool-start "$nome"
}


STEP yum -y install centos-release-qemu-ev epel-release
STEP yum -y install qemu-kvm-ev libvirt-client libvirt-daemon-kvm virt-manager virt-install

STEP systemctl enable libvirtd
STEP systemctl enable libvirt-guests

STEP systemctl start  libvirtd
STEP systemctl start  libvirt-guests

STEP virsh list

STEP cp -f "${DIR_EXTRA_FILES}/virsh_bash_completion" /etc/bash_completion.d/virsh_bash_completion

# verifica se possui storage-pool cadastrado
ret=$(RUN virsh -q pool-list --all | wc -l)
if [ "$ret" = "0" ] ; then
	virsh_create_pool_dir "default" "/publico/vm/images"
	virsh_create_pool_dir "iso"     "/publico/vm/iso"
	RUN virsh pool-list --all --details
fi

# verifica se possui network cadastrado
ret=$(RUN virsh -q net-list --all | wc -l)
if [ "$ret" = "0" ] ; then
	STEP virsh net-define "${DIR_EXTRA_FILES}/libvirt_net_default.xml"
	STEP virsh net-autostart default
	STEP virsh net-start     default
	RUN virsh net-list --all
fi

