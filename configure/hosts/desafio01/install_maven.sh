#!/bin/bash

. lib_configure.sh

MAVEN_URL="http://mirror.nbtelecom.com.br/apache/maven/maven-3/3.5.4/binaries/apache-maven-3.5.4-bin.tar.gz"
MAVEN_VERSION="3.5.4"
PKG_DIR="apache-maven-3.5.4"
PKG_BIN_DIR="${PKG_DIR}/bin"
OUTFILE="maven.tar.gz"

TMPDIR="/dados/temp"
OUTPATH="${TMPDIR}/${OUTFILE}"
INSTBASE="/dados/apps"
INSTDIR="${INSTBASE}/${PKG_DIR}"
VERSION_FILE="${INSTDIR}/INSTALLED_VERSION"

STEP yum -y install curl

STEP mkdir -p "$TMPDIR"

DOWNLOAD_FILE "${MAVEN_URL}" "${OUTPATH}"

version=$(cat "${VERSION_FILE}")
if [ "$version" != "$MAVEN_VERSION" ] ; then
	STEP rm -Rf "${INSTDIR}"
	STEP tar zxvf "$OUTPATH" -C "$INSTBASE"	
	[ ! -d "$INSTDIR" ] && DIE "Diretório de instalação não encontrado: $INSTDIR"
	echo "$MAVEN_VERSION" >"${VERSION_FILE}"
	OK "Maven $MAVEN_VERSION instalado em $INSTDIR"
else
	OK "Maven $MAVEN_VERSION já instalado em $INSTDIR"
fi
ADD_LINE "/etc/profile.d/jasf-maven.sh" 'export PATH=$PATH:'"${INSTBASE}/${PKG_BIN_DIR}" "^export PATH="

OK "Concluído!"
