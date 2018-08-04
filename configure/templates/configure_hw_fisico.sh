#!/bin/bash


. ../lib/lib_configure.sh


#----------------------------------------------------------------------
GROUP "Dependências"
STEP yum -y install epel-release


#----------------------------------------------------------------------
GROUP "Ferramentas para servidor físico"
STEP yum -y install lm_sensors smartmontools atop htop
STEP sensors-detect --auto
STEP sensors


#----------------------------------------------------------------------
# Para corrigir o BUG de lentidão de pvscan na inicialização: --skip-mappings
STEPI "HACK: atualizar thin_check_options em lvm.conf" augtool '
rm /files/etc/lvm/lvm.conf/global/dict/thin_check_options
set /files/etc/lvm/lvm.conf/global/dict/thin_check_options/list/1/str "-q"
set /files/etc/lvm/lvm.conf/global/dict/thin_check_options/list/2/str "--clear-needs-check-flag"
set /files/etc/lvm/lvm.conf/global/dict/thin_check_options/list/3/str "--skip-mappings"
'


#----------------------------------------------------------------------
for d in /dev/sd? ; do
	RUN smartctl -T permissive --smart=on --offlineauto=on --saveauto=on $d
done

OK "Concluído"

