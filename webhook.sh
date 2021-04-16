#!/bin/mksh
while true; do
	input=$(printf '%s\n' "HTTP/1.1 200 OK" "" | socat - TCP4-LISTEN:14112,reuseaddr \
		| tail -n 2)
	if [[ "$input" != "" ]]; then
		./neekshellbot.sh "$input" &
	fi
done
