#!/bin/mksh
socat -T 0.01 tcp-l:14112,reuseaddr,fork system:./getinput.sh
