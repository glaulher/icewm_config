#!/bin/bash

output="<JWM>
	<Menu label=\"Themes\" icon=\"preferences-desktop-theme\">"
suf="		<Separator/>
		<Program label=\"Update themes list\" confirm=\"false\">update-jwm-themes.sh</Program>
	</Menu>
</JWM>"


dirlist="$(ls -1 $HOME/.jwm/themes)"
while read line
do
	entry="<Program label=\"${line}\" confirm=\"false\">jwm-set-theme --restart \"${line}\"</Program>"
	output="${output}\n\t\t${entry}"
done <<< "$dirlist"

output="${output}\n${suf}"

echo -e "$output" > "$HOME/.jwm/themes-list"
jwm -reload
