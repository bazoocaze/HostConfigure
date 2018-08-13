#!/bin/bash


. ../lib/lib_configure.sh || exit 1


SOURCE_KEYS="${DIR_EXTRA_FILES}/authorized_keys"


#---------------------------------------------
GROUP "Preparar authorized_keys"

PREPARE_AUTHORIZED_KEYS "/root/.ssh/authorized_keys"      "root.root"
PREPARE_AUTHORIZED_KEYS "/home/jose/.ssh/authorized_keys" "jose.jose"


#---------------------------------------------
GROUP "Inclusão de chaves públicas"

while read tipo chave tag ; do
	if [ -n "$chave" ] ; then
		ADD_LINE "/root/.ssh/authorized_keys"      "$tipo $chave $tag" "$chave"
		ADD_LINE "/home/jose/.ssh/authorized_keys" "$tipo $chave $tag" "$chave"
	fi
done <<<$(grep -v '#.*' "${SOURCE_KEYS}")

