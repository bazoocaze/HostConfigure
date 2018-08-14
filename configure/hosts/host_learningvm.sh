#!/bin/bash

. ../lib/lib_configure.sh || exit 1


run_super()
{
TEMPLATE basic_workstation
TEMPLATE ssh_keys
TEMPLATE virt_guest
TEMPLATE graphic_server
TEMPLATE display_manager
TEMPLATE mate_desktop
TEMPLATE mate_desktop set-default
}


run_user()
{
url="http://mirror.nbtelecom.com.br/apache/maven/maven-3/3.5.4/binaries/apache-maven-3.5.4-bin.tar.gz"
INSTALL_FROM_URL "$url" --tool mvn

url="http://download.springsource.com/release/STS/3.9.5.RELEASE/dist/e4.8/spring-tool-suite-3.9.5.RELEASE-e4.8.0-linux-gtk-x86_64.tar.gz"
INSTALL_FROM_URL "$url" --app STS --categories "Development;IDE"

url="https://services.gradle.org/distributions/gradle-4.9-bin.zip"
INSTALL_FROM_URL "$url"
}


if [ "$(id -u)" = "0" ] ; then
	run_super
else
	run_user
fi

