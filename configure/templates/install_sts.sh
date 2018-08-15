#!/bin/bash

. ../lib/lib_configure.sh || exit 1

GROUP "STS - Spring Tool Suite"

url="http://download.springsource.com/release/STS/3.9.5.RELEASE/dist/e4.8/spring-tool-suite-3.9.5.RELEASE-e4.8.0-linux-gtk-x86_64.tar.gz"
INSTALL_FROM_URL "$url" --app STS --categories "Development;IDE"

OK "Spring Tool Suite"

