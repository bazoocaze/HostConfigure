#!/bin/bash
######################################################################
# Script.....: deploy_rsa_keys.sh
# Autor......: Jose Ferreira - Olvebra
# Data.......: 2018-08-28 11:12
# Objetivo...: Deploy/autorização de chaves RSA em hosts remotos
######################################################################


currentuser="$USER"


DEBUG=0
DRYRUN=0
YES=0


CFG_OVERWRITE=""
OP_OVERWRITE=""
GET_TMP_FILE=""


outerr()
{
echo "$*" 1>&2
}


die()
{
outerr "FATAL: $*"
exit 1
}


is_dryrun()
{
[ "$DRYRUN" = 1 ]
}


is_debug()
{
[ "$DEBUG" = 1 ]
}


is_yes()
{
[ "$YES" = 1 ]
}


logok()
{
outerr "OK: $*"
}


loginfo()
{
outerr "INFO: $*"
}


logerr()
{
outerr "ERRO: $*"
}


EXEC()
{
local ret
is_debug && outerr "EXEC: $*"
"$@" ; ret=$?
[ "$ret" != 0 ] && outerr "[exit=$ret]"
return "$ret"
}


EXECD()
{
local ret
is_debug && outerr "EXECD: $*"
is_dryrun && return 0
"$@" ; ret=$?
[ "$ret" != 0 ] && outerr "[exit=$ret]" 
return "$ret"
}


confirm()
{
local op
local msg="$1"
	while true ; do

		printf "%s" "${msg} [y/n] " 1>&2

		if is_yes ; then
			outerr "[yes]"
			REPLY="y"
			return 0
		fi

		read op 1>&2 || {
			outerr "[cancel]"
			REPLY="c"
			return 1
		}

		op="${op:0:1}"

		case "$op" in
			s|y|S|Y|1|t|T) outerr "[yes]" ; REPLY="y" ; return 0 ;;
			n|N|0|f|F)     outerr "[no]" ; REPLY="n" ; return 0 ;;
			*)             outerr "[opção inválida]" ;;	
		esac

	done
}


choice()
{
local op
local msg="$1"
local options="$2"
local def="${3:-y}"
	while true ; do

		printf "%s" "${msg} " 1>&2

		if is_yes ; then
			outerr "[${def}]"
			REPLY="${def}"
			return 0
		fi

		read op 1>&2 || {
			outerr "[cancel]"
			REPLY="cancel"
			return 1
		}

		op="${op:0:1}"
		if [ -n "$op" ] ; then
			if [[ "${op}" =~ ${options} ]] ; then
				outerr "[${op}]"
				REPLY="${op}"
				return 0
			fi
		fi

		outerr "[opção inválida]"
	done
}


# Permite ignorar chaves em modo "auto" (--yes)
# true/0 = ignore, false/1 = not ignore
ignore_keyfile()
{
local keyfile="$1"
is_yes || return 1
# if echo "$keyfile" | grep -q 'foobar' ; then
# 	# ignora a chave
# 	return 0
# fi
return 1
}


get_tmp_file()
{
local nomebase="$1"
local path
	path="/tmp/${RANDOM}-${nomebase}-$$.tmp"
	echo "" >"${path}" || return 1
	GET_TMP_FILE="$path"
	return 0
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


deploy_rsa_keys()
{
local target="$1"
local user="$2"
local connection
local key keyfile localdir remotedir

	[ -z "$1" -o -z "$2" ] && die "deploy_rsa_keys(target=$1, user=$2): parâmetros inválidos"

	loginfo "----------"
	loginfo "Deploy de chaves RSA para ${user}@${target}"

	localdir=$(get_ssh_dir "${currentuser}") || return 1
	remotedir=$(get_ssh_dir "${user}")       || return 1
	connection="${user}@${target}"

	if [ ! -d "$localdir" ] ; then
		logerr "Diretório local não encontrado: $localdir"
		return 1
	fi

	EXECD ssh "${connection}" "
		mkdir -p '${remotedir}'
		chown '${user}.${user}' '${remotedir}'
		chmod 700 '${remotedir}'
	" || return 1

	if [ "$OP_OVERWRITE" = 1 ] ; then
		# remove as chaves pre-existentes
		loginfo "Removendo chaves pré-existentes"
		EXECD ssh "${connection}" "rm -f \"${remotedir}\"/*id_rsa*"
	fi

	for key in "${localdir}"/*id_rsa* ; do
		echo "--------------"
		echo "Key: $key"
		keyfile="$(basename "$key")"

		if ignore_keyfile "$key" ; then
			loginfo "Ignorando a chave"
			continue
		fi

		confirm "Deploy da chave $keyfile ?" || return 1
		[ "$REPLY" = "n" ] && continue

		EXECD scp "${key}" "${user}@${target}:${remotedir}" || return 1
		EXECD ssh "${connection}" "
			chown '${user}.${user}' '${remotedir}/${keyfile}'
			chmod 600 '${remotedir}/${keyfile}'
		" || return 1
	done
}


authorize_keys_for_user()
{
local target="$1"
local user="$2"
local connection
local key keyfile localdir remotedir authfile keydata localauthfile
local updated=0

	[ -z "$1" -o -z "$2" ] && die "authorize_keys_for_user(target=$1, user=$2): parâmetros inválidos"

	loginfo "----------"
	loginfo "Autorização de chave pública para ${user}@${target}"

	localdir=$(get_ssh_dir "${currentuser}") || return 1
	remotedir=$(get_ssh_dir "${user}")       || return 1
	connection="${user}@${target}"
	authfile="${remotedir}/authorized_keys"
	
	get_tmp_file "deploy" || return 1
	localauthfile="${GET_TMP_FILE}"

	if [ ! -d "$localdir" ] ; then
		logerr "Diretório local não encontrado: $localdir"
		return 1
	fi

	loginfo "Preparando diretório remoto"
	EXECD ssh "${connection}" "
		mkdir -p '${remotedir}'
		chown '${user}.${user}' '${remotedir}'
		chmod 700 '${remotedir}'
		touch '${authfile}'
		chown '${user}.${user}' '${authfile}'
		chmod 600 '${authfile}'
	" || return 1

	if [ "$OP_OVERWRITE" = 0 ] ; then
		loginfo "Download da autorização remota"
		# copia o arquivo remoto para local
		EXECD scp "${connection}:${authfile}" "${localauthfile}" || return 1
	else
		loginfo "Sobreescrevendo autorização remota"
		EXEC printf "" >"${localauthfile}" || return 1
		updated=1
	fi

	for key in "${localdir}"/*id_rsa.pub ; do

		keyfile="$(basename "$key")"
		keydata="$(cat "$key" | cut -d' ' -f2)"

		echo "--------------"
		echo "Key: $key"

		if ignore_keyfile "$key" ; then
			loginfo "Ignorando a chave"
			continue
		fi

		if [ "$OP_OVERWRITE" = 0 ] ; then
			if grep -v "^#" "${localauthfile}" | grep -q "${keydata}" ; then
				loginfo "a autorização já está presente"
				continue
			fi
		fi

		confirm "Autorizar chave $keyfile ?" || return 1
		[ "$REPLY" = "n" ] && continue

		loginfo "atualizando a autorização"
		cat "${key}" >>"${localauthfile}"
		updated=1

	done

	if [ "$updated" = 1 ] ; then
		loginfo "Upload da autorização remota"

		# copia de volta o arquivo atualizado (para .tmp)
		EXECD scp "${localauthfile}" "${connection}:${authfile}.tmp" || return 1

		# sobreescreve e acerta as permissões do arquivo remoto
		EXECD ssh "${connection}" "
			cat '${authfile}.tmp' >'${authfile}'
			chown '${user}.${user}' '${authfile}'
			chmod 600 '${authfile}'
			rm -f '${authfile}.tmp'
		" || return 1
		logok "autorização de chave pública registrada para ${connection}"
	else
		logok "nenhuma atualização necessária para ${connection}"
	fi

	EXEC rm -f "${localauthfile}"
}


cmd_authorize_keys()
{
local target="$1"
local users="$2"
local item

	[ -z "$1" -o -z "$2" ] && die "cmd_authorize_keys(target=$1, users=$2): parâmetros inválidos"

	OP_OVERWRITE="${CFG_OVERWRITE}"
	if [ -z "$OP_OVERWRITE" ] ; then
		choice "Adicionar ou sobreescrever as autorizações existentes?" "[as]" "a" || return 1
		if [ "$REPLY" = "a" ] ; then
			OP_OVERWRITE=0
		else
			OP_OVERWRITE=1
		fi
	fi

	for item in ${users} ; do
		authorize_keys_for_user "$target" "$item" || return 1
	done
	return 0
}


cmd_deploy_private()
{
local target="$1"
local users="$2"
local item

	[ -z "$1" -o -z "$2" ] && die "cmd_deploy_private(target=$1, users=$2): parâmetros inválidos"

	OP_OVERWRITE="${CFG_OVERWRITE}"
	if [ -z "$OP_OVERWRITE" ] ; then
		choice "Adicionar chaves ou remover/sobreescrever existentes?" "[ars]" "a" || return 1
		if [ "$REPLY" = "a" ] ; then
			OP_OVERWRITE=0
		else
			OP_OVERWRITE=1
		fi
	fi

	for item in ${users} ; do
		deploy_rsa_keys "$target" "$item" || return 1
	done
	return 0
}


cmd_deploy_all()
{

	[ -z "$1" -o -z "$2" ] && die "cmd_deploy_all(target=$1, users=$2): parâmetros inválidos"

	cmd_authorize_keys  "$@" || return 1
	cmd_deploy_private "$@"
}


cmd_help()
{
echo "Deploy de RSA keys para o host remoto"
echo "Uso: [opções] <comando> <target_host> <lista_usuarios>"
echo ""
echo "Opções podem ser:"
echo " -d                 modo debug"
echo " -n                 modo dryrun"
echo " -y ou --yes        confirma/responde sim para as perguntas"
echo " -f ou --overwrite  sobreescreve ao invés de adicionar chaves/autorizações"
echo ""
echo "Comando pode ser:"
echo "  auth              autoriza chaves publicas em authorized_keys"
echo "  deploy            deploy das chaves publicas e privadas"
echo "  all               deploy das chaves publicas e privadas e autorização"
echo ""
echo "Parâmetros:"
echo "  Target host:     Nome de host ou ip de destino (SSH server deve estar rodando)"
echo "  Lista usuarios:  Lista de usuários entre aspas separados por espaços"
echo ""
echo "Configuração:"
echo "  USER=$USER		Indica de qual usuário local serão copiadas as chaves"
exit 1
}


main()
{
local op ret

	while (( $# > 0 )) ; do
		op="$1"
		case "$op" in
			-n)       DRYRUN=1 ;;
			-d)       DEBUG=1 ;;
			-y|--yes) YES=1 ;;
			-f|--overwrite) CFG_OVERWRITE=1 ;;
			--help)   cmd_help ;;
			-*)       die "Opção inválida: $op" ;;
			*)        break ;;
		esac
		shift
	done

	[ "$#" = 0 ] && cmd_help

	op="$1" ; shift
	case "$op" in
		dep|deploy)      cmd_deploy_private "$@" ;;
		auth|authorize)  cmd_authorize_keys "$@" ;;
		all)             cmd_deploy_all     "$@" ;;
		*)               cmd_help ;;
	esac

	ret=$?

	if [ -f "${GET_TMP_FILE}" ] ; then
		EXEC rm -f "${GET_TMP_FILE}"
	fi

	return "$ret"
}


main "$@"

