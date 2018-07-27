#!/bin/bash

exec 4>&1
exec 5>&2

stdout()
{
echo "$*" 1>&4
}

stderr()
{
echo "$*" 1>&5
}

OK()
{
stdout "---OK: $*"
}

ERROR()
{
stderr "---ERRO: $*"
}

DIE()
{
stderr "---FATAL: $*"
exit 1 
}

MSG()
{
stdout "---$*"
}

ASSERT()
{
local n=0
{
echo "---ASSERT: $*"
while caller $(( n++ )) ; do
	true
done
} >&5
exit 126
}

EXEC()
{
MSG "EXEC: $*"
"$@" 4>&- 5>&- ; ret=$?
[ "$ret" != 0 ] && ERROR "[exit=$ret]"
return "$ret"
}

RUN()
{
MSG "RUN: $*"
"$@" 4>&- 5>&- ; ret=$?
[ "$ret" != 0 ] && ERROR "[exit=$ret]"
return "$ret"
}

STEP()
{
local ret
MSG "STEP: $*"
"$@" 4>&- 5>&- ; ret=$?
[ "$ret" != 0 ] && DIE "[exit=$ret]"
return "$ret"
}

DOWNLOAD_FILE()
{
local url="$1"
local output="$2"
local okfile="${output}-download-ok"
local okurl
	[ -z "${url}" -o -z "${output}" ] && ASSERT "DOWNLOAD_FILE($1, $2): parâmetros incorretos"

	if [ -f "$output" -a -f "${okfile}" ] ; then
	   okurl=$(cat "${okfile}")
	   if [ "${okurl}" = "$url" ] ; then
	      OK "Arquivo já baixado de ${url}"
	      return 0
	   fi
	fi
   STEP rm -f "${okfile}"
	STEP curl --retry 12 --retry-delay 15 -C - -f -o "${output}" "${url}"
	echo "${url}" >"${okfile}"
}

ADD_LINE()
{
local file="$1"
local line="$2"
local search="$3"
local bakfile="${file}.bak"
	[ -z "$file" -o -z "$line" ] && ASSERT "ADD_LINE($1, $2, $3): parâmetros incorretos"

	MSG "ADD_LINE: Atualizando o arquivo $file: $line"
	
	if [ -f "$file" ] ; then
		if grep -ql "$line" "$file" ; then
			OK "Arquivo $file nenhuma atualização necessária"
			return 0
		fi
	else
		EXEC touch "$file" || DIE "Impossível acessar o arquivo $file"
	fi
	EXEC cp "$file" "$bakfile" || DIE "Impossível copiar $file para $bakfile"
	[ -z "$search" ] && search="$line"	
	grep -ve "$search" "$bakfile" >"$file"
	echo "$line" >>"$file"
	colordiff "$bakfile" "$file"

	OK "Arquivo $file atualizado com sucesso"
}

ADD_CRONTAB()
{
local cmd="$1"
local options="$2"
local line="${options} ${cmd}"
local tmpfile
local h1 h2
	[ -z "$cmd" -o -z "$options" ] && ASSERT "ADD_CONTRAB($1, $2): parâmetros incorretos"
	MSG "ADD_CRONTAB: atualizando comando $cmd opções: $options"
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

PROMPT()
{
local msg="$1"
local linha
	export REPLY=""
	while true ; do
		printf "%s: " "$msg"
		read linha || {
			stdout "[EOF]"
			return 1
		}
		if [ -z "$linha" ] ; then
			stderr " Aviso: o valor não pode ficar em branco"
			continue
		fi
		export REPLY="$linha"
		return 0
	done
}

CONFIRM()
{
local msg="$1"
local linha
local c
	while true ; do
		printf "%s [y/n] " "$msg"
		read linha || {
			stdout "[EOF]"
			return 2
		}
		if [ -z "$linha" ] ; then
			continue
		fi	
		c="${linha:0:1}"
		echo "[c=$c]"
		case $c in
			y|Y|s|S|1|t|T) stdout "[yes]" ; return 0 ;;
			n|N|0|f|F)     stdout "[no]" ; return 1 ;;
			*) stderr "Aviso: opção inválida" ;;
		esac
	done
}
