#!/bin/bash

. lib_configure.sh

STS_URL="http://download.springsource.com/release/STS/3.9.5.RELEASE/dist/e4.8/spring-tool-suite-3.9.5.RELEASE-e4.8.0-linux-gtk-x86_64.tar.gz"
PKG_DIR="sts-bundle"
PKG_BIN_DIR="${PKG_DIR}/sts-3.9.5.RELEASE"
STS_VERSION=4.8.0
OUTFILE="sts.tar.gz"

TMPDIR="/dados/temp"
OUTPATH="${TMPDIR}/${OUTFILE}"
INSTBASE="/dados/apps"
INSTDIR="${INSTBASE}/${PKG_DIR}"
VERSION_FILE="${INSTDIR}/INSTALLED_VERSION"

STEP yum -y install curl

STEP mkdir -p "$TMPDIR"

DOWNLOAD_FILE "${STS_URL}" "${OUTPATH}"

version=$(cat "${VERSION_FILE}")
if [ "$version" != "$STS_VERSION" ] ; then
   STEP rm -Rf "${INSTDIR}"
   STEP tar zxvf "$OUTPATH" -C "$INSTBASE"
   [ ! -d "$INSTDIR" ] && DIE "Diretório de instalação não encontrado: $INSTDIR"
   echo "$STS_VERSION" >"${VERSION_FILE}"
   OK "STS $STS_VERSION instalado em $INSTDIR"
else
   OK "STS $STS_VERSION já instalado em $INSTDIR"
fi
ADD_LINE "/etc/profile.d/jasf-sts.sh" 'export PATH=$PATH:'"${INSTBASE}/${PKG_BIN_DIR}" "^export PATH="

cat >"/home/jose/.local/share/applications/SpringToolSuite.desktop" <<EOF
#!/usr/bin/env xdg-open
[Desktop Entry]
Name=Spring Tool Suite
GenericName=Spring Tool Suite
GenericName=Spring Tool Suite
Comment=The Spring Tool Suite is an Eclipse-based development environment that is customized for developing Spring applications.
TryExec=/dados/apps/sts-bundle/sts-3.9.5.RELEASE/STS
Exec=${INSTBASE}/${PKG_BIN_DIR}/STS
Icon=${INSTBASE}/${PKG_BIN_DIR}/icon.xpm
Type=Application
Categories=Development;IDE
StartupNotify=true
EOF

OK "Concluído!"
