#!/bin/mksh
toptext=$1 mode=$2 media=$3 size=12
if [[ "$(grep -P '[\p{Han}]' <<< "$toptext")" ]]; then
	font="Noto Sans CJK HK"
else
	font="FuturaPTCondExtraBold"
fi
get_line_th() {
	ffmpeg -v 24 -hide_banner -f lavfi -i color \
		-vf "drawtext=$font:fontsize=$fs:textfile=$1:y=print(th\,24)" \
		-vframes 1 -f null - 2>&1 | sed -n 1p | sed 's/\..*//'
}
get_res() {
	[[ ! -e "$2" ]] && return
	case "$1" in
		width|height)
			local p=$1
			ffprobe -v error -show_streams "$2" \
				| sed -n "s/^$p=\(.*\)/\1/p"
		;;
	esac
}

w=$(get_res width "$media")
ps=$(bc <<< "$w/$size")
magick -font "$font" -size ${w}x -gravity center \
	-pointsize $ps -define pango:markup=false \
	pango:"$(printf '%s\n' "$toptext")" "in.png"

mh=$(get_res height "$media")
ch=$(get_res height "in.png")
h=$(bc <<< "$ch+$mh")
case "$mode" in
	top)
		py=$ch
		oy=0
	;;
	bottom)
		py=0
		oy=$mh
	;;
esac

if [[ "${file_type[1]}" == "sticker" ]]; then
	ext="png"
	convert "$media" "sticker.png"
	media="sticker.png"
fi

ffmpeg -v error -y -i "$media" -filter_complex \
	"pad=h=$h:y=$py" \
	"pad.$ext"

ffmpeg -v error -y -i "pad.$ext" -i "in.png" -filter_complex \
	"overlay=y=$oy" "toptext.$ext"

if [[ "$ext" == "png" ]] && [[ "${file_type[1]}" == "sticker" ]]; then
	convert "toptext.$ext" "toptext.webp"
	ext=webp
fi
