#!/bin/bash

. ../lib/lib_configure.sh || exit 1

GROUP "Maven"

url="http://mirror.nbtelecom.com.br/apache/maven/maven-3/3.5.4/binaries/apache-maven-3.5.4-bin.tar.gz"
INSTALL_FROM_URL "$url" --tool mvn

OK "Maven instalado"

