#!/bin/mksh
while true; do
	input=$(printf '%s\n' "HTTP/1.1 200 OK" "" \
		| nc -l -N -p 14112 \
		| tail -n 2)
	[[ "$input" != "" ]] && ./neekshellbot.sh "$input"
done
