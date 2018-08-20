#!/bin/bash
######################################################################
# Script....: setup.sh
# Author....: Jose Ferreira
# Date......: 2018-08-20 13:19
# Info......: Setup program for the zramswap package
######################################################################


VERSION="1.03 2018-08-20 20:20"
# VERSION="1.02 2018-08-20 16:40"

### Commandline config ###
DEBUG=0
DRYRUN=0

### Other config ###
APPDESC="The ZRAM-Swap Package"
TARGET_BINDIR="/usr/local/sbin"
TARGET_SVCDIR="/etc/systemd/system"
SERVICES="zram-swap"
BIN_FILES=("zramswapon" "zramswapoff")
SVC_FILES=("zram-swap.service")

### Constants ###
P_INSTALLED=0
P_NOT_INSTALLED=1
P_PARTIAL_INSTALLED=2


outerr()
{
echo "$*" 1>&2
}


logok()
{
echo "OK: $*"
}


logerr()
{
outerr "ERROR: $*"
}


logdebug()
{
is_debug && outerr "DEBUG: $*"
}


is_debug()
{
[ "$DEBUG" = 1 ]
}


is_dryrun()
{
[ "$DRYRUN" = 1 ]
}


EXECD()
{
local ret
is_debug && outerr "EXECD: $*"
is_dryrun && return 0
"$@" ; ret=$?
[ "$ret" != 0 ] && logdebug "[exit=$ret]"
return "$ret"
}


verify()
{
local found=0
local notfound=0
local item file

	for item in "${BIN_FILES[@]}" ; do
		file="${TARGET_BINDIR}/${item}"
		if [ -f "$file" ] ; then
			found=1
		else
			notfound=1
		fi
	done

	for item in "${SVC_FILES[@]}" ; do
		file="${TARGET_SVCDIR}/${item}"
		if [ -f "$file" ] ; then
			found=1
		else
			notfound=1
		fi
	done

	case "${found}${notfound}" in
		10) echo "installed" ; return "${P_INSTALLED}" ;;
		01) echo "not installed" ; return "${P_NOT_INSTALLED}" ;;
		11) echo "partial installed" ; return "${P_PARTIAL_INSTALLED}" ;;
		00) echo "unknow state" ; return "${P_PARTIAL_INSTALLED}" ;;
	esac
}


is_installed()
{
local ret
local desc
	desc="$(verify)" ; ret=$?
	[ "$ret" = "${P_INSTALLED}" ]
}


is_not_installed()
{
local ret
local desc
	desc="$(verify)" ; ret=$?
	[ "$ret" = "${P_NOT_INSTALLED}" ]
}


do_install()
{
local ret=0

	for item in "${BIN_FILES[@]}" ; do
		logdebug "Installing file ${item}"
		EXECD install "$item" "${TARGET_BINDIR}" || {
			ret=$?
			logerr "Failed to install file $item"
			return "$ret"
		}
	done

	for item in "${SVC_FILES[@]}" ; do
		logdebug "Installing service ${item}"
		EXECD cp -f "$item" "${TARGET_SVCDIR}" || {
			ret=$?
			logerr "Failed to install service $item"
			return "$ret"
		}
	done

	EXECD systemctl daemon-reload

	for item in "${SERVICES[@]}" ; do
		logdebug "Enabling service ${item}"
		EXECD systemctl enable "${item}" || ret=$?

		logdebug "Starting service ${item}"
		EXECD systemctl start  "${item}" || ret=$?
	done

	if [ "$ret" = 0 ] ; then
		logok "Installation completed"
	else
		logerr "Installation complete with errors"
	fi

	return "$ret"
}


do_remove()
{
local ret=0

	EXECD systemctl daemon-reload

	for item in "${SERVICES[@]}" ; do
		logdebug "Stopping service ${item}"
		EXECD systemctl stop    "${item}" || ret=$?

		logdebug "Disabling service ${item}"
		EXECD systemctl disable "${item}" || ret=$?
	done

	for item in "${SVC_FILES[@]}" ; do
		logdebug "Removing service ${item}"
		EXECD rm -f "${TARGET_SVCDIR}/${item}" || ret=$?
	done

	for item in "${BIN_FILES[@]}" ; do
		logdebug "Removing file ${item}"
		EXECD rm -f "${TARGET_BINDIR}/${item}" || ret=$?
	done

	if [ "$ret" = 0 ] ; then
		logok "Uninstallation completed"
	else
		logerr "Uninstallation complete with errors"
	fi

	return "$ret"
}


cmd_install()
{
	if is_installed ; then 
		logok "The package is already installed"
		return 0
	fi
	do_install
}


cmd_remove()
{
	if is_not_installed ; then 
		logok "The package is not installed"
		return 0
	fi
	do_remove
}


cmd_reinstall()
{
do_remove
do_install
}


cmd_status()
{
local strstatus="$(verify)"
	printf "%s is %s\n" "${APPDESC}" "${strstatus}"
	return 0
}


cmd_help()
{
echo "${APPDESC} v${VERSION}"
echo "Usage: [options] <command>"
echo "Options:"
echo " -d         debug mode"
echo " -n         dry run mode"
echo " --help     show help"
echo "Commands:"
echo " install    install the package"
echo " remove     uninstall the package"
echo " reinstall  reinstall the package (same as remove then install)"
echo " status     show package installation status"
echo " help       show help"
echo "Configuration:"
echo " VERSION       = $VERSION"
echo " DEBUG         = $DEBUG"
echo " DRYRUN        = $DRYRUN"
echo " TARGET_BINDIR = $TARGET_BINDIR"
echo " TARGET_SVCDIR = $TARGET_SVCDIR"
echo " SERVICES      = ${SERVICES[*]}"
echo " SVC_FILES     = ${SVC_FILES[*]}"
echo " BIN_FILES     = ${BIN_FILES[*]}"
exit 1
}


main()
{
local op

	while (( $# > 0 )) ; do
		op="$1"
		case "$op" in
			-d) DEBUG=1 ;;
			-n) DRYRUN=1 ;;
			--help) cmd_help ;;
			-) logerr "Invalid option: $op" ; cmd_help ;;
			*) break ;;
		esac
		shift
	done

	[ "$#" = 0 ] && cmd_help

	op="$1"

	case "$op" in
		help)      cmd_help ;;
		install)   cmd_install ;;
		remove)    cmd_remove ;;
		reinstall) cmd_reinstall ;;
		status)    cmd_status ;;
		*)         logerr "Invalid command: $op" ; cmd_help ;;
	esac
}


main "$@"

