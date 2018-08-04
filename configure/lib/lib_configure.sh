#!/bin/bash

LIB_CONFIGURE_VERSION="1.01 2018-08-01 15:14"

CL_NORMAL=$(echo -n -e "\e[0m")
CL_ERROR=$(echo -n -e "\e[41m")
CL_INFO=$(echo -n -e "\e[44m")
CL_ITEM=$(echo -n -e "\e[44m")
CL_OK=$(echo -n -e "\e[30;42m")
CL_WARNING=$(echo -n -e "\e[30;43m")
CL_DEBUG=$(echo -n -e "\e[96m")
CL_GROUP=$(echo -n -e "\e[30;43m")


# Variárveis globais:
#  YES
#  NO
#  VERBOSE
#  DEBUG
#  DRYRUN
#  DIR_LIBCFG
#  DIR_EXTRA_FILES
#  DIR_TEMPLATES


stdout()
{
echo "$*" 1>&4
}


stderr()
{
echo "$*" 1>&5
}


to_stdout()
{
cat 1>&4
}


to_stderr()
{
cat 1>&5
}


is_debug()
{
[ "$DEBUG" = "1" ]
}


is_verbose()
{
[ "$VERBOSE" = "1" ] 
}


is_dryrun()
{
[ "$DRYRUN" = "1" ]
}


is_yes()
{
[ "$YES" = "1" ]
}


is_no()
{
[ "$NO" = "1" ]
}


EXEC()
{
local ret
DEBUG "EXEC: $*"
"$@" 4>&- 5>&- ; ret=$?
[ "$ret" != "0" ] && DEBUG "[ret=$ret]"
return "$ret"
}


EXECD()
{
local ret
DEBUG "EXECD: $*"
is_dryrun && return 0
"$@" 4>&- 5>&- ; ret=$?
[ "$ret" != "0" ] && DEBUG "[ret=$ret]"
return "$ret"
}


MSG()
{
stdout "*** $*"
}


DEBUG()
{
is_debug && MSG "${CL_DEBUG}DEBUG: ${*}${CL_NORMAL}"
}


DIE()
{
MSG "${CL_ERROR}FATAL: ${*}${CL_NORMAL}"
exit 1
}


ERROR()
{
MSG "${CL_ERROR}ERRO: ${*}${CL_NORMAL}"
}


OK()
{
MSG "${CL_OK}OK: ${*}${CL_NORMAL}" 
}


WARN()
{
MSG "${CL_WARNING}AVISO: ${*}${CL_NORMAL}"
}


INFO()
{
MSG "${CL_INFO}${*}${CL_NORMAL}"
}


BANNER()
{
echo "      $*      " | sed 's/./-/g'
echo "|     $*     |"
echo "      $*      " | sed 's/./-/g'
}


GROUP()
{
echo ""     | to_stdout
BANNER "$1" | to_stdout
}


ITEM()
{
MSG "${CL_ITEM}${*}${CL_NORMAL}"
}


ASSERT()
{
local n=0
{
echo ""
echo "------------------------------" 
echo "${CL_ERROR}ASSERT: ${*}${CL_NORMAL}"
echo "Callstack:"
while caller $(( n++ )) ; do
	true
done
} | to_stderr
exit 1
}


FILE_HASH()
{
local ret=$(md5sum "$1" 2>/dev/null | cut -f1 -d' ')
	if [ -z "$ret" ] ; then
		echo -n "-"
		return 1
	else
		echo -n "$ret"
		return 0
	fi
}


RUNI()
{
local info="$1"
local ret
	shift
	[ -z "$*" ] && ASSERT "RUNI($info, $*): parâmetros inválidos"
	[ -z "$info" ] && info="$*"
	ITEM "RUN: ${info}" 
	EXECD "$@" ; ret=$?
	is_dryrun && return 0
	if [ "$ret" -eq 0 ] ; then
		OK "$info" 
		return 0
	fi
	is_debug || WARN "[exit=$ret]" 
	return "$ret"
}


RUN()
{
local info="$*"
	RUNI "$info" "$@"
}


STEPI()
{
local info="$1"
local ret
	shift
	[ -z "$*" ] && ASSERT "STEPI($info, $*): parâmetros inválidos"
	[ -z "$info" ] && info="$*"
	ITEM "PASSO: ${info}" 
	EXECD "$@" ; ret=$?
	is_dryrun && return 0
	if [ "$ret" -eq 0 ] ; then
		OK "$info" 
		return 0
	fi
	DIE "[exit=$ret]" 
}


STEP()
{
	STEPI "$*" "$@"
}


ADD_LINE()
{
local file="$1"
local line="$2"
local search="$3"
local bakfile="${file}.bak"
local tmpfile="${file}.tmp"

	[ -z "$file" -o -z "$line" ] && ASSERT "ADD_LINE(file=$1, line=$2, search=$3): parâmetros inválidos"

	ITEM "PASSO: Adicionar linha em ${file}: $line" 
	if [ -f "$file" ] ; then
		if grep -ql "$line" "$file" ; then
			OK "arquivo ${file} nenhuma alteração necessária" ; return 0
		fi
	fi

	touch "$file"            || DIE "Impossível acessar o arquivo $file"
	cp -f "$file" "$bakfile" || DIE "Impossível copiar $file para $bakfile"
	[ -z "$search" ] && search="$line"	
	grep -ve "$search" "$bakfile" >"${tmpfile}"
	printf "%s" "$line"           >>"${tmpfile}"
	is_verbose && colordiff "${bakfile}" "${tmpfile}"
	if ! is_dryrun ; then
		cat "${tmpfile}" >"${file}"
		OK "arquivo atualizado: ${file}"
	fi
	rm -f "${tmpfile}"
	return 0
}


WRITE_FILE()
{
local file="$1"
local content="$2"
local tmpfile="${file}-tmp"
local h1 h2
	[ "$#" -eq 0 -o "$#" -gt 2 ] && ASSERT "WRITE_FILE($1, $2): parâmetros inválidos"
	ITEM "PASSO: Gravar arquivo ${file}" 
	if [ "$#" -eq 1 ] ; then
		timeout 8 cat /dev/stdin >"$tmpfile" || {
			rm -f "${tmpfile}"
			ASSERT "WRITE_FILE falhou lendo de stdin"
		}
	else
		echo -n "$content" >"$tmpfile"
	fi
	h1=$(FILE_HASH "$file")
	h2=$(FILE_HASH "$tmpfile")
	if [ "$h1" = "$h2" ] ; then
		OK "arquivo ${file} nenhuma alteração necessária" ; return 0
	else
		if ! is_dryrun ; then
			cat "$tmpfile" >"$file"
			OK "arquivo atualizado: ${file}"
		fi
	fi
	rm -f "${tmpfile}"
	return 0
}


WM_SET_DEFAULT()
{
local nome=$(basename "$1")
local cmd_pref
local cmd_desk

	[ -z "$nome" ] && ASSERT "WM_SET_DEFAULT($1): parâmetros inválidos"

	case "$1" in
		gnome-classic)
			cmd_pref=""
			cmd_desk=""
			;;
		GNOME|KDE)
			cmd_pref=""
			cmd_desk="$1"
			;;
		*)
			cmd_pref="$1"
			cmd_desk=""
			;;
	esac

	RUN touch /etc/sysconfig/desktop

	STEPI "Ajustando desktop padrão '$nome' em /etc/sysconfig/desktop" \
		augtool "
			set /files/etc/sysconfig/desktop/PREFERRED '${cmd_pref}'
			set /files/etc/sysconfig/desktop/DESKTOP   '${cmd_desk}'"

	is_verbose && RUN cat /etc/sysconfig/desktop
}


# Prepara o arquivo authorized_keys do usuário
PREPARE_AUTHORIZED_KEYS()
{
local file="$1"
local user="$2"
local path=$(dirname "$file")

	[ -z "$file" -o -z "$user" -o -z "$path" ] && ASSERT "PREPARE_AUTHORIZED_KEYS($1, $2, $3): parâmetros inválidos"

   STEP mkdir -p      "$path"
   STEP chmod 700     "$path"
   STEP chown "$user" "$path"
   STEP touch         "$file"
   STEP chmod 600     "$file"
   STEP chown "$user" "$file"
}


DOWNLOAD_FILE()
{
local url="$1"
local output="$2"
local okfile="${output}-download-ok"
local okurl

	[ -z "${url}" -o -z "${output}" ] && ASSERT "DOWNLOAD_FILE(url=$1, output=$2): parâmetros incorretos"

	ITEM "DOWNLOAD_FILE: baixando a url ${url}"

	if [ -f "$output" -a -f "${okfile}" ] ; then
	   okurl=$(cat "${okfile}")
	   if [ "${okurl}" = "$url" ] ; then
	      OK "Arquivo já baixado de ${url}"
	      return 0
	   fi
	fi
	rm -f "${okfile}" || DIE "Impossível apagar o arquivo ${okfile}"
	STEP curl --retry 12 --retry-delay 15 -C - -f -o "${output}" "${url}"
	echo "${url}" >"${okfile}"
	OK "Download concluído"
}


ADD_CRONTAB()
{
local cmd="$1"
local options="$2"
local line="${options} ${cmd}"
local tmpfile
local h1 h2

	[ -z "$cmd" -o -z "$options" ] && ASSERT "ADD_CONTRAB(cmd=$1, options=$2): parâmetros incorretos"

	ITEM "ADD_CRONTAB: atualizando comando:[$cmd] opções:[$options]"

	tmpfile="/tmp/add_cron_$$.tmp"
	crontab -l >"$tmpfile"
	h1=$(md5sum "$tmpfile") || DIE "Falha ao obter hash de $tmpfile"
	ADD_LINE "$tmpfile" "$line" "${cmd}\$" 
	h2=$(md5sum "$tmpfile")
	if [ "$h1" != "$h2" ] ; then
		crontab "$tmpfile" || DIE "Falha ao atualizar a crontab"
		OK "crontab: atualizada com sucesso"
	else
		OK "crontab: nenhuma atualização necessária"
	fi
	rm -f "$tmpfile"
}


internal_run_template()
{
local name="$1"
local path="$2"
local lasttarget="$CONFTARGET"

	[ -z "$1" -o -z "$2" ] && ASSERT "internal_run_template(name=$1, path=$2): parâmetros incorretos"

	shift ; shift

	ITEM "TEMPLATE: $name"			

	[ -n "$1" ] && CONFTARGET="$1"
	export CONFTARGET
	"$path" || DIE "TEMPLATE: ${name} [exit=$?]"
	OK "TEMPLATE: $name"
	CONFTARGET="$lasttarget"
	return 0
}


TEMPLATE()
{
local name="$1"
local prefix=("" "configure_" "template_")
local suffix=("" ".sh")
local path file pre suf ret

	[ -z "$name" ] && ASSERT "TEMPLATE(name=$1): parâmetros inválidos"

	shift

	if [ -x "$name" ] ; then
		internal_run_template "$(basename "${name}")" "${name}" "$@"
		return $?
	fi

   for pre in "${prefix[@]}" ; do
      for suf in "${suffix[@]}" ; do
         file="${pre}${name}${suf}"
         path="${DIR_TEMPLATES}/${file}"
			if [ -x "$path" ] ; then
				internal_run_template "${file}" "${path}" "$@"
				return $?
			fi
      done
   done

	DIE "Template ${name} não encontrado"
}


# A rotina pede configuramação e retorna true em caso de "sim"
# Códigos de retorno: 0=sim ou (YES=1), 1=não, 2=ESC/EOF/Timeout
# Encerra o script caso seja informado 'q'
CONFIRM()
{
local msg="$1"
local op ret
local timeout=5

	msg="$msg [y/n]"

	while true ; do
		printf "%s" "${msg} "

		is_yes && {
			stderr "[y](-y)"
			return 0
		}

		is_no && {
			stderr "[n](--no)"
			return 1
		}

		read -t "$timeout" op ; ret=$?
		if [ "$ret" != 0 ] ; then
			case $ret in
				142) stderr "[n][timeout]" ;;
				1)   stderr "[n][EOF]" ;;
				*)   stderr "[n][sem resposta]" ;;
			esac
			return 2	
		fi

		[ -z "$op" ] && continue

		op=${op:0:1}

		case $op in
			y|Y|s|S|1) return 0 ;;
			n|N|0)     return 1 ;;
			q)         exit 1 ;;
			$'\x1b')   stderr "(ESC)" ; return 2 ;;
		esac
		stderr " WARNING: invalid input: [$op]"
	done
	return 2
}


# A rotina pede uma entrada por stdin e retorno true em caso de sucesso
# Códigos de retorno: 0=sim ou (YES=1), 1=não, 2=ESC/EOF/Timeout
# Encerra o script caso seja informado 'q'
PROMPT()
{
local msg="$1"
local op ret size
local timeout=5
local minsize=${2:-0}
	while true ; do
		printf "%s " "$msg"

		is_yes && {
			stderr "[sem resposta](-y)"
			return 1
		}

		is_no && {
			stderr "[sem resposta](--no)"
			return 1
		}

		read -t "$timeout" op ; ret=$?
		if [ "$ret" = 0 ] ; then
			size="${#op}"
			if (( size < minsize )) ; then
				(( size > 0 )) && stderr "[Informe pelo menos ${minsize} caracter(es)]"
				continue
			fi
			export REPLY="$op"
			return 0
		fi

		case $ret in
			142) stderr "[timeout]" ;;
			1)   stderr "[EOF]" ;;
			*)   stderr "[sem resposta]" ;;
		esac
		return 1
	done
}


# retorna true para a primeira execução do pragma
PRAGMA_ONCE()
{
local name="_PRAGMA_ONCE_${1}"
[ "${!name}" = "1" ] && return 1
export "${name}"=1 || exit 1
return 0
}


cmd_help_lib_configure()
{
echo "Uso: [opções] <comando>"
echo "Opções diponíveis:"
echo " -d       mostra informações de debug"
echo " -n       modo dryrun"
echo " -v       modo verboso: mostra mais informações"
echo " -y       responde sim para as perguntas e confirmações"
echo " --no     responde não para as perguntas e confirmações"
echo "Comandos:"
echo " CONFTARGET=[install|remove|undo|set-default]"
echo "Variáveis disponíveis para o script:"
printf " %-30s %s\n" "YES=$YES"               "definido pela opção -y"
printf " %-30s %s\n" "VERBOSE=$VERBOSE"       "definido pela opção -v"
printf " %-30s %s\n" "DEBUG=$DEBUG"           "definido pela opção -d"
printf " %-30s %s\n" "DRYRUN=$DRYRUN"         "definido pela opção -n"
printf " %-30s %s\n" "CONFTARGET=$CONFTARGET" "target informado pelo usuário"

printf " %-30s %s\n" "diretório da biblioteca"   "DIR_LIBCFG=$DIR_LIBCFG"
printf " %-30s %s\n" "diretório dos extra files" "DIR_EXTRA_FILES=$DIR_EXTRA_FILES"
printf " %-30s %s\n" "diretório dos templates"   "DIR_TEMPLATES=$DIR_TEMPLATES"
exit 1
}


is_lib_configure_option()
{
case "$1" in
	-y|-v|-d|-n|--help-configure) return 0 ;;
	*)                            return 1 ;;
esac
}


lib_configure_entry_point()
{
# FD 4 é stdout do script
# FD 5 é stderr to script
exec 4>&1
exec 5>&2

export DIR_LIBCFG="$(realpath "$(dirname "${BASH_SOURCE[0]}")")"
export DIR_EXTRA_FILES="$(realpath "${DIR_LIBCFG}/../extra_files")"
export DIR_TEMPLATES="$(realpath "${DIR_LIBCFG}/../templates")"

# export lib_configure_dir=$(dirname "

while [ "$#" -gt "0" ] ; do
	case "$1" in
		-y)   NO=0 ; YES=1    ;;
		--no) YES=0 ; NO=1    ;;
		-v)   VERBOSE=1       ;;
		-d)   DEBUG=1         ;;
		-n)   DRYRUN=1        ;;
		install|remove|set-default|undo) CONFTARGET="$1" ;;
		--help-configure) cmd_help_lib_configure ;;
		*)  WARN "Parâmetro não reconhecido: $1" ;;
	esac
	shift
done

export CONFTARGET NO YES VERBOSE DEBUG DRYRUN

[ -z "$CONFTARGET" ] && CONFTARGET="install"

DEBUG "lib_configure_entry_point(): [-d|-n|-v|-y|--no|--help-configure]"
}


# Processa a linha de comando
PRAGMA_ONCE "lib_configure_sh" && lib_configure_entry_point "$@"

true

