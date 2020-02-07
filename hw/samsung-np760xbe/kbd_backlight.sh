#!/bin/bash

DISP=/sys/firmware/efi/efivars/KBDBacklitLvl-5af56f53-985c-47d5-920c-f1c531d06852
LEVEL_ON="0700000005"
LEVEL_OFF="0700000000"

cmd_get() {
xxd -p "$DISP"
}

cmd_set_level() {
chattr -i $DISP
echo "$1" | xxd -p -r >$DISP
chattr +i $DISP
cmd_get
}

case "$1" in
   set)   cmd_set_level $LEVEL_ON ;;
   clear) cmd_set_level $LEVEL_OFF ;;
   *)     cmd_get ;;
esac

