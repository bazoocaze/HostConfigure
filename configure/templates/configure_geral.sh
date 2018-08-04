#!/bin/bash


. ../lib/lib_configure.sh || exit 1


### ----------------------------------------------
GROUP "Repositórios e pacotes básicos"
STEP yum -y install deltarpm
STEP yum -y install epel-release 
STEP yum -y install mc git vim colordiff bash-completion bash-completion-extras wget curl net-tools augeas

# STEPI "Trocar LANG do sistema para inglês" augtool 'set /files/etc/locale.conf/LANG en_US.UTF-8'

### ----------------------------------------------
### Firewall
GROUP "Firewall"
STEP systemctl stop    firewalld
STEP systemctl disable firewalld

STEP yum -y install iptables-services
STEP systemctl stop    ip6tables
STEP systemctl disable ip6tables
STEP systemctl stop    iptables
STEP systemctl disable iptables


# ### ----------------------------------------------
# ### Configuração do SSH-server
# GROUP "SSH-server"
# STEP groupadd -f -g 1050 ssh_users
# STEP usermod -a -G ssh_users jose
# STEP usermod -a -G ssh_users root
# STEP augtool set "/files/etc/ssh/sshd_config/AllowGroups/1" "ssh_users"
# STEP systemctl restart sshd


### ----------------------------------------------
### Preferências de configuração
GROUP "Preferências"
ADD_LINE "/etc/vimrc" "highlight Comment ctermfg=green" "" "\" by jose antonio - olvebra"
ADD_LINE "/etc/vimrc" "set ts=3" ""                        "\" by jose antonio - olvebra"
STEP git config --system color.diff auto
STEP git config --system color.ui auto
STEP augtool 'set /files/etc/yum.conf/main/clean_requirements_on_remove 1'
STEP augtool 'set /files/etc/yum.conf/main/installonly_limit 3'


# ### ----------------------------------------------
# ### Configuração /opt/olvebra
# GROUP "Configuração /opt/olvebra"
# STEP mkdir -p /opt/olvebra/bin /opt/olvebra/sbin /opt/olvebra/etc
# ADD_LINE "/etc/profile.d/olvebra.sh" 'export PATH=$PATH:/opt/olvebra/bin:/opt/olvebra/sbin' ""


### ----------------------------------------------
### Samba
GROUP "SAMBA"
STEP yum -y install samba samba-client cifs-utils
# STEP augtool set '/files/etc/samba/smb.conf/target[.="global"]/workgroup'      'OLVEBRA'
STEP augtool set '/files/etc/samba/smb.conf/target[.="global"]/map\ to\ guest' 'Bad\ User'
STEP augtool set '/files/etc/samba/smb.conf/target[.="global"]/load\ printers' 'no'
STEP systemctl enable smb
STEP systemctl enable nmb
STEP systemctl start  smb
STEP systemctl start  nmb


# ### ----------------------------------------------
# ### Postfix
# GROUP "Postfix"
# STEP augtool <<EOF
# set /files/etc/postfix/main.cf/mydestination localhost
# set /files/etc/postfix/main.cf/networks_style host
# set /files/etc/postfix/main.cf/relayhost sntolvebra.intranet
# set /files/etc/postfix/main.cf/mydomain olvebra.com.br
# set /files/etc/postfix/main.cf/myorigin olvebra.com.br
# set /files/etc/postfix/main.cf/smtpd_recipient_restrictions 'permit_mynetworks\ reject_unauth_destination'
# set /files/etc/postfix/main.cf/smtpd_client_restrictions permit_inet_interfaces
# save
# EOF
# STEP systemctl restart postfix


### ----------------------------------------------
### LVM (discard)
GROUP "LVM"
STEP augtool set '/files/etc/lvm/lvm.conf/devices/dict/issue_discards/int 1'


### ----------------------------------------------
### Hardening
GROUP "Hardening"
ADD_LINE "/etc/cron.allow" "root"


# ### ----------------------------------------------
# ### Etckeeper
# GROUP "Etckeeper"
# STEP yum -y install etckeeper
# STEP etckeeper init
# STEP augtool -t "Shellvars incl '/etc/etckeeper/etckeeper.conf'" set '/files/etc/etckeeper/etckeeper.conf/AVOID_DAILY_AUTOCOMMITS 1'
# STEP chmod 700 /etc/.git

OK "Concluído"

