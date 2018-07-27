#!/bin/bash

. lib_configure.sh

DOCKERVG="vg_extra"


STEP yum -y install docker docker-compose

# STEP rm -f /etc/sysconfig/docker-storage

STEP augtool "
	set /files/etc/sysconfig/docker-storage-setup/STORAGE_DRIVER devicemapper
	set /files/etc/sysconfig/docker-storage-setup/VG             ${DOCKERVG}"

STEP docker-storage-setup

RUN groupadd docker
STEP usermod -aG docker jose

ADD_LINE "/dados/bin/jobreboot.sh" "#!/bin/bash"
ADD_LINE "/dados/bin/jobreboot.sh" "systemctl start docker"
ADD_LINE "/dados/bin/jobreboot.sh" "chown root.docker /var/run/docker.sock" "chown .* /var/run/docker.sock"
STEP chmod +x "/dados/bin/jobreboot.sh"

ADD_CRONTAB "/dados/bin/jobreboot.sh" "@reboot"

STEP systemctl enable docker
STEP systemctl start  docker

OK "Concluído!"

