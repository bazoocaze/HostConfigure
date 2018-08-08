#!/bin/bash


. ../lib/lib_configure.sh || exit 1


GROUP "Desativar serviços não utilizados"
STEP systemctl stop    kdump
STEP systemctl disable kdump
STEP systemctl stop    firewalld
STEP systemctl disable firewalld


### ----------------------------------------------
GROUP "Repositórios e pacotes básicos"
STEP yum -y install deltarpm
STEP yum -y install epel-release 
STEP yum -y install mc git vim colordiff bash-completion bash-completion-extras wget curl net-tools augeas


### ----------------------------------------------
### Firewall
GROUP "Firewall"
STEP yum -y install iptables-services
STEP systemctl stop    ip6tables
STEP systemctl disable ip6tables
STEP systemctl stop    iptables
STEP systemctl disable iptables


### ----------------------------------------------
### Preferências de configuração
GROUP "Preferências"
ADD_LINE "/etc/vimrc" "highlight Comment ctermfg=green" ""
ADD_LINE "/etc/vimrc" "set ts=3" ""                       
STEP git config --system color.diff auto
STEP git config --system color.ui auto
STEP augtool 'set /files/etc/yum.conf/main/clean_requirements_on_remove 1'
STEP augtool 'set /files/etc/yum.conf/main/installonly_limit 3'


### ----------------------------------------------
### Samba
GROUP "SAMBA"
STEP yum -y install samba samba-client cifs-utils
STEP augtool set '/files/etc/samba/smb.conf/target[.="global"]/map\ to\ guest' 'Bad\ User'
STEP augtool set '/files/etc/samba/smb.conf/target[.="global"]/load\ printers' 'no'
STEP systemctl enable smb
STEP systemctl enable nmb
STEP systemctl start  smb
STEP systemctl start  nmb


### ----------------------------------------------
### LVM (discard)
GROUP "LVM"
STEP augtool set '/files/etc/lvm/lvm.conf/devices/dict/issue_discards/int 1'


### ----------------------------------------------
### Hardening
GROUP "Hardening"
ADD_LINE "/etc/cron.allow" "root"


OK "Concluído"

