#!/bin/mksh
media=$1 gtext=$2 size=7
get_res() {
    [[ ! -e "$2" ]] && return
    case "$1" in
        width|height)
            local p=$1
            local res=$(ffprobe -v error -show_streams "$2" \
                | sed -n "s/^$p=\(.*\)/\1/p")
        ;;
    esac
    printf '%s' "$res"
}

w=$(get_res width "$media")
cw=$((w-(w/10)))
ps=$(bc <<< "$w/$size")
font="@$HOME/.local/share/fonts/upright.otf"
convert \
	-background none -fill white -font "$font" \
	-stroke black -strokewidth 15 \
	-gravity center -pointsize $ps \
	-size $((cw+10))x caption:"$gtext" "$media" \
	+swap -compose over -composite \
	"out-0.png"
convert \
	-background none -fill white -font "$font" \
	-gravity center -pointsize $ps \
	-size ${cw}x caption:"$gtext" "out-0.png" \
	+swap -compose over -composite \
	"gblog.png"
