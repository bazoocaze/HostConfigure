#!/bin/bash


VERSION="1.02 2020-07-06"
TARGET="/usr/share/X11/xkb/"

cmd_apply() {
#generated with: diff -u -r ./symbols/br ../mod/symbols/br
patch -N -p1 -d "$TARGET" --reject-file - 
}


cmd_apply <<EOF
--- ./symbols/br	2020-07-06 22:04:19.448978827 -0300
+++ ../mod/symbols/br	2020-07-06 22:04:19.452978929 -0300
@@ -25,7 +25,7 @@
     key <AD12> { [  bracketleft,      braceleft,   ordfeminine,     dead_macron ] };
     key <BKSL> { [ bracketright,     braceright,     masculine,       masculine ] };
 
-    key <AC10> { [     ccedilla,       Ccedilla,    dead_acute,dead_doubleacute ] };
+    key <AC10> { [     ccedilla,       Ccedilla,           bar,       backslash ] };
     key <AC11> { [   dead_tilde,dead_circumflex,    asciitilde,     asciicircum ] };
 
     key <LSGT> { [    backslash,            bar,     masculine,      dead_breve ] };
EOF
