#!/bin/bash

. lib_configure.sh

STEP yum -y install gcc gcc-c++ make dkms kernel-devel kernel-headers-$(uname -r)

STEP usermod -a -G vboxsf jose

OK "Concluído!"
