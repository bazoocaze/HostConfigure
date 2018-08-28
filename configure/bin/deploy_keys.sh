#!/bin/bash


currentuser="jose"


die()
{
echo "FATAL: $*" 1>&2
exit 1
}


EXEC()
{
local ret
echo "EXEC: $*" 1>&2
"$@" ; ret=$?
[ "$ret" != 0 ] && echo "[exit=$ret]" 1>&2
return "$ret"
}


get_ssh_dir()
{
local user="$1"

	[ -z "$1" ] && die "get_ssh_dir(user=$1): parâmetros inválidos"

	if [ "$user" = "root" ] ; then
		printf "/root/.ssh"
	else
		printf "/home/%s/.ssh" "${user}"
	fi

	return 0
}


rsa_deploy()
{
local target="$1"
local user="$2"
local connection
local key keyfile localdir remotedir

	[ -z "$1" -o -z "$2" ] && die "rsa_deploy(target=$1, user=$2): parâmetros inválidos"

	localdir=$(get_ssh_dir "${currentuser}") || return 1
	remotedir=$(get_ssh_dir "${user}")       || return 1
	connection="${user}@${target}"

	EXEC ssh "${connection}" "
		mkdir -p '${remotedir}'
		chown '${user}.${user}' '${remotedir}'
		chmod 700 '${remotedir}'
	" || return 1

	for key in "${localdir}"/*id_rsa* ; do
		echo "--------------"
		echo "Key: $key"
		keyfile="$(basename "$key")"
		EXEC scp "${key}" "${user}@${target}:${remotedir}" || return 1
		EXEC ssh "${connection}" "
			chown '${user}.${user}' '${remotedir}/${keyfile}'
			chmod 600 '${remotedir}/${keyfile}'
		" || return 1
	done
}


cmd_help()
{
echo "Deploy das chaves RSA"
echo "Uso: <target_host> <nome_usuario>"
exit 
}


[ "$#" = 0 ] && cmd_help


rsa_deploy "$1" "$2"

