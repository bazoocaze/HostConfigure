#!/bin/bash

EXEC()
{
local ret
echo "EXEC: $*" 1>&2
"$@" ; ret=$?
[ "$ret" != 0 ] && echo "[exit=$ret]" 1>&2
return "$ret"
}

FILE="/boot/grub2/grub.cfg"
BAK="${FILE}.bak"

EXEC cp -f "$FILE" "$BAK" || exit 1

EXEC grub2-mkconfig -o "$FILE" || {
	EXEC cp -f "$BAK" "$FILE"
	exit 1
} 

EXEC colordiff "$BAK" "$FILE"

exit 0
