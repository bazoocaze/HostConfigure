#!/bin/bash


VERSION="1.01 2020-03-11"
TARGET="/usr/share/X11/xkb/"


cmd_apply() {
patch -N -p1 -d "$TARGET" --reject-file - 
}


cmd_apply <<EOF
diff -u -r ./rules/base.lst ../mod/rules/base.lst
--- ./rules/base.lst	2020-02-08 23:44:54.009911769 -0300
+++ ../mod/rules/base.lst	2020-02-08 23:46:14.025718750 -0300
@@ -390,6 +390,7 @@
   nativo-us       br: Portuguese (Brazil, Nativo for US keyboards)
   nativo-epo      br: Esperanto (Brazil, Nativo)
   thinkpad        br: Portuguese (Brazil, IBM/Lenovo ThinkPad)
+  samsungnp760    br: Portuguese (Brazil, Samsung NP760)
   phonetic        bg: Bulgarian (traditional phonetic)
   bas_phonetic    bg: Bulgarian (new phonetic)
   ber             dz: Berber (Algeria, Tifinagh)
diff -u -r ./rules/base.xml ../mod/rules/base.xml
--- ./rules/base.xml	2020-02-08 23:45:01.523931106 -0300
+++ ../mod/rules/base.xml	2020-02-08 23:47:13.520569664 -0300
@@ -2356,6 +2356,12 @@
             <description>Portuguese (Brazil, IBM/Lenovo ThinkPad)</description>
           </configItem>
         </variant>
+        <variant>
+          <configItem>
+            <name>samsungnp760</name>
+            <description>Portuguese (Brazil, Samsung NP760)</description>
+          </configItem>
+        </variant>
       </variantList>
     </layout>
     <layout>
@@ -7388,4 +7394,4 @@
       </option>
     </group>
   </optionList>
-</xkbConfigRegistry>
\ No newline at end of file
+</xkbConfigRegistry>
diff -u -r ./rules/evdev.lst ../mod/rules/evdev.lst
--- ./rules/evdev.lst	2020-02-08 23:44:54.009911769 -0300
+++ ../mod/rules/evdev.lst	2020-02-08 23:46:26.474436669 -0300
@@ -390,6 +390,7 @@
   nativo-us       br: Portuguese (Brazil, Nativo for US keyboards)
   nativo-epo      br: Esperanto (Brazil, Nativo)
   thinkpad        br: Portuguese (Brazil, IBM/Lenovo ThinkPad)
+  samsungnp760    br: Portuguese (Brazil, Samsung NP760)
   phonetic        bg: Bulgarian (traditional phonetic)
   bas_phonetic    bg: Bulgarian (new phonetic)
   ber             dz: Berber (Algeria, Tifinagh)
diff -u -r ./rules/evdev.xml ../mod/rules/evdev.xml
--- ./rules/evdev.xml	2020-02-08 23:45:01.523931106 -0300
+++ ../mod/rules/evdev.xml	2020-02-08 23:47:22.760719118 -0300
@@ -2356,6 +2356,12 @@
             <description>Portuguese (Brazil, IBM/Lenovo ThinkPad)</description>
           </configItem>
         </variant>
+        <variant>
+          <configItem>
+            <name>samsungnp760</name>
+            <description>Portuguese (Brazil, Samsung NP760)</description>
+          </configItem>
+        </variant>
       </variantList>
     </layout>
     <layout>
@@ -7388,4 +7394,4 @@
       </option>
     </group>
   </optionList>
-</xkbConfigRegistry>
\ No newline at end of file
+</xkbConfigRegistry>
Only in ../mod/rules: xfree86
Only in ../mod/rules: xfree86.lst
Only in ../mod/rules: xfree86.xml
Only in ../mod/rules: xorg
Only in ../mod/rules: xorg.lst
Only in ../mod/rules: xorg.xml
diff -u -r ./symbols/br ../mod/symbols/br
--- ./symbols/br	2020-02-08 23:39:27.991323846 -0300
+++ ../mod/symbols/br	2020-03-09 16:05:18.599601512 -0300
@@ -308,3 +308,15 @@
 	xkb_symbols "sun_type6" {
 	include "sun_vndr/br(sun_type6)"
 };
+
+// The ABNT2 keyboard on Samsung NP760
+// by JASF
+partial alphanumeric_keys
+xkb_symbols "samsungnp760" {
+
+    include "br(abnt2)"
+    name[Group1]="Portuguese (Brazil, Samsung NP760)";
+
+    key <AC10> { [  ccedilla,  Ccedilla,  bar, backslash ] };
+
+};
EOF
