#!/bin/bash

LIB_CONFIGURE_VERSION="1.03b 2018-08-22 11:38"
# LIB_CONFIGURE_VERSION="1.03 2018-08-22 11:38"
# LIB_CONFIGURE_VERSION="1.02 2018-08-10 11:55"

CL_NORMAL=$(echo -n -e "\e[0m")
CL_ERROR=$(echo -n -e "\e[41m")
CL_INFO=$(echo -n -e "\e[44m")
CL_ITEM=$(echo -n -e "\e[44m")
CL_OK=$(echo -n -e "\e[30;42m")
CL_WARNING=$(echo -n -e "\e[30;43m")
CL_DEBUG=$(echo -n -e "\e[96m")
CL_VERBOSE="${CL_DEBUG}"
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


# Determina o nome/versão do sistema operacional
# Retorna o resultado nas variáveis:
#  DISTRIB_ID      = centos|linuxmint|ubuntu
#  DISTRIB_RELEASE = 1
#  OS              = centos7|linuxmint19
os_probe()
{
[ -n "${DISTRIB_ID}" ] && return 0

if [ -f "/etc/lsb-release" ] ; then
	. /etc/lsb-release
	[ -z "${DISTRIB_ID}" ]      && ERROR "Impossível obter o nome da versão do sistema (/etc/lsb-release)"
	[ -z "${DISTRIB_RELEASE}" ] && ERROR "Impossível obter o número da versão do sistema (/etc/lsb-release)"
	if [ -n "${DISTRIB_ID}" -a -n "${DISTRIB_RELEASE}" ] ; then
		DISTRIB_ID="$(echo "${DISTRIB_ID}" | tr 'A-Z' 'a-z')"
		OS="${DISTRIB_ID}${DISTRIB_RELEASE}"
		return 0
	fi
elif [ -f "/etc/os-release" ] ; then
	. /etc/os-release
	[ -z "${ID}" ]         && ERROR "Impossível obter o nome da versão do sistema (/etc/os-release)"
	[ -z "${VERSION_ID}" ] && ERROR "Impossível obter o número da versão do sistema (/etc/os-release)"
	if [ -n "${ID}" -a -n "${VERSION_ID}" ] ; then
		DISTRIB_ID="$(echo "${ID}" | tr 'A-Z' 'a-z')"
		DISTRIB_RELEASE="${VERSION_ID}"
		OS="${DISTRIB_ID}${DISTRIB_RELEASE}"
		return 0
	fi
else
	ERROR "Impossível obter o nome/número da versão do sistema - distribuição desconhecida"
fi
DISTRIB_ID="unknow"
DISTRIB_RELEASE="XX"
OS="${DISTRIB_ID}${DISTRIB_RELEASE}"
return 1
}


get_os_name()
{
os_probe
printf "%s" "${DISTRIB_ID}" 
return 0
}


get_os_version()
{
os_probe
printf "%s" "${DISTRIB_RELEASE}" 
return 0
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


VERBOSE()
{
is_verbose && MSG "${CL_VERBOSE}VERBOSE: ${*}${CL_NORMAL}"
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


SUB_STEP()
{
local info="$*"
local ret
	[ -z "$*" ] && ASSERT "SUB_STEP($*): parâmetros inválidos"
	DEBUG " SUB-PASSO: ${info}"
	EXECD "$@" ; ret=$?
	is_dryrun && return 0
	if [ "$ret" != 0 ] ; then
		ERROR "[exit=$ret]"
		DIE "Falha no sub-passo: ${info}"
	fi
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
		if grep -qF "$line" "$file" ; then
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


get_download_hash()
{
local url="$1"
local file="$2"

	[ -z "$1" -o -z "$2" ] && ASSERT "get_download_hash(url=$1, file=$2): parâmetros incorretos"

	{
		echo "${url}"    | md5sum | cut -f1 -d" "
		md5sum "${file}" | cut -f1 -d" "
	} | md5sum | cut -f1 -d" "
}


DOWNLOAD_FILE()
{
local url="$1"
local output="$2"
local okfile="${output}-download-ok"
local h1 h2

	[ -z "${url}" -o -z "${output}" ] && ASSERT "DOWNLOAD_FILE(url=$1, output=$2): parâmetros incorretos"

	ITEM "DOWNLOAD_FILE: baixando a url ${url}"

	if [ -f "$output" -a -f "${okfile}" ] ; then
		h1=$(get_download_hash "${url}" "${output}")
	   h2=$(cat "${okfile}")
		DEBUG "h1=${h1}  h2=${h2}"
	   if [ "${h1}" = "${h2}" ] ; then
	      OK "Arquivo já baixado de ${url}"
	      return 0
		else
			INFO "Hash do download anterior não confere (ou URL mudou). Baixando novamente..."
	   fi
	fi
	rm -f "${okfile}" || DIE "Impossível apagar o arquivo ${okfile}"
	rm -f "${output}" || DIE "Impossível apagar o download anterior: ${output}"
	# STEP curl --retry 12 --retry-delay 15 -f -o "${output}" "${url}"
	STEP wget -O "${output}" "${url}"
	get_download_hash "${url}" "${output}" >"${okfile}"
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


camel_case()
{
local input="$1"
	printf "%s" "$input" | to_camel_case
}


to_camel_case()
{
sed -r 's/(^|[^[:alpha:]])(\w)/\1\U\2/g;'
}


get_icon_for_program()
{
local exe="$1"
local name dir item list nome tipo

	[ -z "$1" ] && ASSERT "get_icon_for_program(exe=$1): parâmetros inválidos"

	name="$(basename "$exe")"
	dir="$(dirname "$exe")"

	namelist=("${name}" "icon")
	typelist=("png" "xpm")

	for nome in "${namelist[@]}" ; do
		for tipo in "${typelist[@]}" ; do
			path="${dir}/${nome}.${tipo}"
			if [ -f "$path" ] ; then
				DEBUG "Encontrado o ícone $path para o programa $exe"
				echo "$path"
				return 0
			fi
		done
	done

	namelist=("application-x-executable.png" "*executable*.png")
	for item in "${namelist[@]}" ; do
		path=$(find /usr/share/icons -type f -name "${item}" | head -n 1)
		if [ -n "$path" -a -f "$path" ] ; then
			DEBUG "Encontrado o ícone $path para o programa $exe"
			echo "$path"
			return 0
		fi
	done

	WARN "Não foi possível encontrar um ícone para o programa $exe"
	return 1
}



get_desktop_menu_dir()
{
local path="${HOME}/.local/share/applications"
	echo "$path"
	[ ! -d "$path" ] && {
		WARN "Diretório de menus não encontrado: $path"
		return 1
	}
	return 0
}


get_boolean()
{
local input="$1"
local out_true="${2:-true}"
local out_false="${3:-false}"

	[ -z "$1" ] && ASSERT "get_boolean(input=$1): parâmetros inválidos"

	case "$input" in
		1|on|true|t|yes|y)  echo "${out_true}" ; return 0 ;;
		0|off|false|t|no|n) echo "${out_false}" ; return 0 ;;
		*) ERROR "Entrada booleana inválida: $input" ; echo "${out_false}" ; return 1 ;;
	esac
}


DESKTOP_SHORTCUT()
{
local target="$1"
local appname="$2"
local appexe="$3"
local appcomment appicon
local appcategories="Utility"
local appterminal="false"
local desktop_dir

	[ -z "$1" -o -z "$2" -o -z "$3" ] && ASSERT "DESKTOP_SHORTCUT(target=$1, appname=$2, appexe=$3): parâmetros inválidos"

	ITEM "DESKTOP SHORTCUT: $appname $appexe"

	shift 3

	while (( $# > 0 )) ; do
		op="$1"
		shift
		case "$op" in
			--comment)    appcomment="$1" ; shift ;;
			--icon)       appicon="$1" ; shift ;;
			--categories) appcategories="$1" ; shift ;;
			--terminal)   appterminal=$(get_boolean "$1") ; shift ;;
			*)            DIE "Opção inválida: $op"
		esac
	done

	[ -z "$appicon" ] && appicon="$(get_icon_for_program "$appexe")"

	desktop_dir="$(get_desktop_menu_dir)" || return 1

	target="${desktop_dir}/$(basename "$target")" 

	if [ -f "$target" ] ; then
		EXEC rm -f "$target"
	fi

{
cat <<EOF
#!/usr/bin/env xdg-open

[Desktop Entry]
Name=${appname}
Comment=${appcomment}
Exec=${appexe}
Icon=${appicon}
Type=Application
Categories=${appcategories}
Terminal=${appterminal}

EOF
} >"$target" 

	OK "Atalho criado com sucesso: $appname"

	return 0
}


get_writable_dir()
{
local adir=("$@")
local item subdir

	for item in "${adir[@]}" ; do
		if [ -w "$item" ] ; then
			echo "$item"
			return 0
		fi
	done

	for item in "${adir[@]}" ; do
		subdir="$(dirname "$item")"
		if [ -w "$subdir" ] ; then
			if mkdir -p "${item}" ; then
				echo "$item"
				return 0
			else
				WARN "Não foi possível criar o diretório: $item"
			fi
		fi
	done
	return 1
}


get_app_dir()
{
	get_writable_dir "/dados/apps" "${HOME}/.apps" || {
		DIE "Não foi possível determinar o diretório para APPs. Os candidatos são: $*"
	}
}


get_download_dir()
{
	get_writable_dir "/dados/downloads" "${HOME}/Downloads" "/tmp/downloads" || {
		DIE "Não foi possível preparar um diretório para downloads. Os candidatos são: $*"
	}
}


create_sh()
{
local file="$1"
	[ -z "$1" ] && ASSERT "create_sh(file=$1): parâmetros inválidos"
	if [ ! -f "$file" ] ; then
		echo "#!/bin/bash" >"$file" || DIE "Impossível criar o arquivo: $file"
	fi
	SUB_STEP chmod 775 "$file"
}


INSTALL_FROM_URL()
{
local url="$1"
local remotefilename filetype progname progversion downloaddir downloadfilename appdir installdir 
local item ret old
local cfgtool cfgapp cfgbin cfgautobin cfgcategories="Other"
local nicename
local bindirs applist
local libid="lib_configure"
local hargs hurl hargs_conf hurl_conf
local instfile

	[ -z "$1" ] && ASSERT "INSTALL_FROM_URL(url=$1): parâmetros inválidos"

	shift

	ITEM "INSTALAR DA URL: $url"

	if [ $# = 0 ] ; then
		cfgautobin=("bin" "sbin")	
		DEBUG "Pesquisa automática de diretórios de ferramentas ativada para ${cfgbin[*]}"
	fi

	hargs="$(echo "${url} $*" | md5sum | cut -f1 -d ' ')"
	hurl="$(echo "${url}" | md5sum | cut -f1 -d ' ')"

	while (( $# > 0 )) ; do
		op="$1"
		shift
		case "$op" in
			--tool)       cfgtool+=("$1") ; shift ;;
			--app)        cfgapp+=("$1") ; shift ;;
			--bin)        cfgbin+=("$1") ; shift ;;
			--auto-bin)   cfgautobin=("bin" "sbin") ;;
			--categories) cfgcategories="$1" ; shift ;;
		esac
	done

	remotefilename="$(basename "$url")"

	case "$remotefilename" in
		*.tar.gz) filetype="tgz" ;;
		*.tgz)    filetype="tgz" ;;
		*.zip)    filetype="zip" ;;
		*)        ASSERT "Tipo de arquivo não suportado para $remotefilename" ;;
	esac

	progname="$(echo "$remotefilename" | sed 's/-\?[[:digit:]].*//g;')"
	progversion="$(echo "$remotefilename" | sed -n 's/[^[:digit:]]*\([[:digit:]]\+\(\.[[:digit:]]\+\)\+\).*/\1/p;')"
	downloaddir="$(get_download_dir)" || return 1
	downloadfilename="${downloaddir}/${progname}.${filetype}"
	appdir="$(get_app_dir)" || return 1
	installdir="${appdir}/${progname}"
	nicename="$(echo "${progname}" | to_camel_case | tr '_-' '  ')"

	instfile="${installdir}/INSTALL_INFO"
	if [ -f "$instfile" ] ; then
		INFO "Encontrada instalação existente de ${progname} em ${installdir}"
		hargs_conf="$(cat "$instfile" | grep "^ARGS" | cut -f2 -d' ')"
		hurl_conf="$(cat "$instfile"  | grep "^URL"  | cut -f2 -d' ')"
		# if [ "${hargs}" = "${hargs_conf}" ]; then
		# 	OK "Nenhuma alteração necessária. Instalação já configurada: ${progname}-${progversion}"
		# 	return 0
		# else
		# 	INFO "Nova instalação necessária para ${progname} em ${installdir}"
		# fi
	fi

	if [ "${hurl}" != "${hurl_conf}" ] ; then
		DOWNLOAD_FILE "$url" "${downloadfilename}"

		if [ -d "${installdir}" ] ; then
			old="${installdir}.old"
			if [ -d "$old" ] ; then
				SUB_STEP rm -Rf "${old}"
			fi
			SUB_STEP mv -f "${installdir}" "${old}"
		fi
		SUB_STEP mkdir -p "${installdir}"

		# descompactar o arquivo
		case "$filetype" in
			tgz)
				SUB_STEP tar zxf "${downloadfilename}" -C "${installdir}"
				;;

			zip)
				SUB_STEP unzip "${downloadfilename}" -d "${installdir}"
				;;
	
			*) ASSERT "Tipo de arquivo não preparado: $filetype" ;;
		esac
	else
		INFO "A URL não mudou. Não é necessário fazer novo download e descomprimir."
	fi

	bindirs=()
	applist=()

	for item in "${cfgtool[@]}" ; do
		ret=$(find "${installdir}" -type f -name "$item" | head -n 1)
		if [ -n "$ret" ] ; then
			INFO "Encontrada ferramenta $item em $ret"
			bindirs+=("$(dirname "$ret")")
		else
			WARN "Ferramenta $item não encontrada na instalação em ${installdir}"
		fi
	done
	
	for item in "${cfgapp[@]}" ; do
		ret=$(find "${installdir}" -type f -name "$item" | head -n 1)
		if [ -n "$ret" ] ; then
			INFO "Encontrado programa $item em $ret"
			applist+=("$ret")
		else
			WARN "Programa '${item}' não encontrado na instalação em ${installdir}"
		fi
	done

	for item in "${cfgbin[@]}" ; do
		ret=$(find "${installdir}" -type d -name "$item" | head -n 1)
		if [ -n "$ret" ] ; then
			INFO "Encontrado diretório de ferramentas em $ret"
			bindirs+=("$ret")
		else
			WARN "Diretório de ferramentas '$item' não encontrado na instalação em ${installdir}"
		fi
	done	

	for item in "${cfgautobin[@]}" ; do
		ret=$(find "${installdir}" -type d -name "$item" | head -n 1)
		if [ -n "$ret" ] ; then
			INFO "Encontrado diretório de ferramentas em $ret"
			bindirs+=("$ret")
		else
			DEBUG "Diretório de ferramentas (auto) $item não encontrado na instalação em ${installdir}"
		fi
	done	

	# criação de atalhos
	for item in "${applist[@]}" ; do
		name="${nicename}"
		if [ "${#applist[@]}" != 1 ] ; then
			name="${name} - $(basename "$item")"
		elif [ -n "$progversion" ] ; then
			name="${name} ${progversion}"
		fi
		DESKTOP_SHORTCUT "${libid}-${progname}-$(basename "$item").desktop" "$name" "$item" --categories "${cfgcategories}"
	done

	if [ "${#bindirs[@]}" != 0 ] ; then
		ret='$PATH'

		# registrar diretórios bin	
		for item in "${bindirs[@]}" ; do
			ret="${ret}:${item}"
		done

		if [ -w "/etc/profile.d" ] ; then
			path="/etc/profile.d/${libid}.sh"
		else
			path="${HOME}/.bash_profile"
		fi

		create_sh "$path"

		ADD_LINE "$path" "export PATH=${ret}" "^export PATH=\$PATH:${installdir}.*"
	fi

	if [ "${hargs}" != "${hargs_conf}" ] ; then
		# Criar o marcado de instalado/configurado com sucesso
		{
			echo "ARGS $hargs"
			echo "URL $hurl"
		} >"${instfile}"
	fi

	OK "Instalação concluída com sucesso: ${progname}-${progversion} em ${installdir}"
	
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
local inputname="$1"
local prefix=("" "configure_" "template_" "install_")
local suffix=("" ".sh")
local topdirs osname osversion dir
local templatename templatesubdir
local path file pre suf ret

	[ -z "$inputname" ] && ASSERT "TEMPLATE(inputname=$1): parâmetros inválidos"

	shift

	templatename="$(basename "$inputname")"
	templatesubdir="$(dirname "$inputname")"

	if [ -x "$inputname" ] ; then
		internal_run_template "${templatename}" "${inputname}" "$@"
		return $?
	fi

	osname=$(get_os_name)
	osversion=$(get_os_version)
	topdirs=("${osname}${osversion}" "${osname}" ".")

	for dir in "${topdirs[@]}" ; do
	   for pre in "${prefix[@]}" ; do
	      for suf in "${suffix[@]}" ; do
	         file="${pre}${templatename}${suf}"
	         path="${DIR_TEMPLATES}/${dir}/${templatesubdir}/${file}"
				VERBOSE " template: $path"
				if [ -x "$path" ] ; then
					internal_run_template "${file}" "${path}" "$@"
					return $?
				fi
	      done
	   done
	done

	DIE "Template ${inputname} não encontrado"
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
echo "Biblioteca lib_configure.sh"
echo "Versão ${LIB_CONFIGURE_VERSION}"
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

{
echo "YES=$YES"                  "|(definido pela opção -y)"
echo "VERBOSE=$VERBOSE"          "|(definido pela opção -v)"
echo "DEBUG=$DEBUG"              "|(definido pela opção -d)"
echo "DRYRUN=$DRYRUN"            "|(definido pela opção -n)"
echo "CONFTARGET=$CONFTARGET"    "|(target informado pelo usuário)"
echo "DISTRIB_ID=${DISTRIB_ID}"            "|(nome da distribuição do sistema operacional)"
echo "DISTRIB_RELEASE=${DISTRIB_RELEASE}"  "|(número de versão da distribuição)"
echo "OS=${OS}"                            "|(nome+versão da distribuição)"
} | column -t -s '|'

{
echo "DIR_LIBCFG=$DIR_LIBCFG"           "|(diretório da biblioteca)"
echo "DIR_EXTRA_FILES=$DIR_EXTRA_FILES" "|(diretório dos extra files)"
echo "DIR_TEMPLATES=$DIR_TEMPLATES"     "|(diretório dos templates)"
} | column -t -s '|'

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

os_probe

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

export CONFTARGET NO YES VERBOSE DEBUG DRYRUN DISTRIB_ID DISTRIB_RELEASE OS

[ -z "$CONFTARGET" ] && CONFTARGET="install"

DEBUG "lib_configure_entry_point(): [-d|-n|-v|-y|--no|--help-configure]"
}


# Processa a linha de comando
PRAGMA_ONCE "lib_configure_sh" && lib_configure_entry_point "$@"

true

