#!/bin/bash 

echo "Checking all Ace3 files"

foundGlobals=0
for listing in `find .. -name "*.lua" -print`; do
	dir=`echo $listing | awk -F '/' '{print $2}'`
	file=`echo $listing | sed 's/^[^/]*\/[^/]*\/\(.*\)$/\1/'`
	if [[ $dir != "tests" && $dir != "benchs" ]]; then
		res=`luac -p -l "$listing" | grep SETGLOBAL`
		if [[ $? == 0 ]]; then
			if [[ $foundGlobals == 0 ]]; then
				tput bold
				echo "Globals found:"
				tput sgr0
			fi
			foundGlobals=1
			echo "$listing:"
			echo $res | awk 'BEGIN { format = "%--50s \033[32m%s\033[0m\n" } { printf format, $7, $2 }'
		fi;
	fi;
done
