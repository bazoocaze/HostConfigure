#!/bin/bash

. ../lib/lib_configure.sh || exit 1


#----------------------------------------------------------------------
GROUP "Dependências"
STEP yum -y install epel-release


#----------------------------------------------------------------------
GROUP "Detectar e configurar virtual guest"

tipo=$(RUN virt-what)
if [ "$?" = "0" -a "$tipo" != "" ] ; then
	tipo=$(virt-what | head -n 1)
	INFO "HYPERVISOR: $tipo"
	case $tipo in

		virtualbox)
			STEP yum -y install gcc gcc-c++ bzip2 make autoconf kernel-devel-$(uname -r) dkms 
			OK "Pode instalar VirtualBox Guest Additions agora"
			;;

		kvm)
			STEP yum -y install qemu-guest-agent
			;;

      *)
			WARN "Virtualização desconhecida: $tipo"
			;; 

	esac

else

	OK "Virtualização não detectada"

fi

