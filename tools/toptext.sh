#!/bin/mksh
toptext=$1 size=3
unfolded=$toptext tt_wc=$(wc -m <<< "$toptext")
res=($(ffprobe -v error -show_streams "video.$ext" | sed -n -e 's/^width=\(.*\)/\1/p' -e 's/^height=\(.*\)/\1/p'))
fs=$(bc <<< "(${res[1]}/$size)/2")
tts="toptext-start"
printf '%s' "$(tr '\n' ' ' <<< "$toptext")" > "$tts"
if [[ "$(grep -P '[\p{Han}]' <<< "$toptext")" ]]; then
	font="font=Noto Sans CJK HK"
else
	font="fontfile=$(realpath ~/.local/share/fonts)/futura.otf"
fi
line_th=$(ffmpeg -v 24 -hide_banner -f lavfi -i color \
	-vf "drawtext=fontfile=$fontfile:fontsize=$fs:textfile=$tts:y=print(th\,24)" \
	-vframes 1 -f null - 2>&1 | sed -n 1p | sed 's/\..*//')
if [[ "$2" == "" ]]; then
	mode=top
else
	mode=bottom
fi
get_nh() {
	if [[ "$1" == "top" ]]; then
		nh=$(bc <<< "${res[1]}+$last_ycord+($line_th/0.9)")
		ypad_cord=$(bc <<< "$last_ycord+($line_th/0.9)")
	else
		nh=$(bc <<< "$last_ycord+($line_th/0.9)")
		ypad_cord=0
	fi
}
drawtext_lines() {
	if [[ "$mode" == "bottom" ]]; then
		ycord=${res[1]}
	else
		ycord=0
	fi
	for x in $(seq $nl -1 1); do
		line=$(sed -n ${x}p <<< "$(tac <<< "$toptext")")
		tf[$x]="toptext-$x"
		printf '%s' "$line" > "${tf[$x]}"
		if [[ "$x" == "$nl" ]]; then
			ycord=$(bc <<< "$ycord+($line_th/4)")
		else
			ycord=$(bc <<< "$ycord+($line_th/1.2)")
		fi
		printf '%s\n' "$ycord($x) res1: ${res[1]}"
		lines[$x]="drawtext=box=1:textfile=${tf[$x]}:$font:fontsize=$fs:y=$ycord:x=(w-tw)/2,"
	done
	last_ycord=$ycord
	drawtext=$(printf '%s' "${lines[@]}" | head -c -1)
	unset lines
}
get_tw() {
	tw=$(ffmpeg -v 24 -hide_banner -f lavfi -i color \
		-vf "drawtext=$font:fontsize=$fs:text=$toptext:x=print(tw\,24)" \
		-vframes 1 -f null - 2>&1 | sed -n 1p | sed 's/\..*//')
	nl=$(wc -l <<< "$toptext")
	w_diff=$(bc <<< "${res[0]}/$tw")
	if [[ "$w_diff" != "0" ]]; then
		line_th=$((line_th+(line_th/4)))
		drawtext_lines
		get_nh "$mode"
		case "$ext" in
			jpg|jpeg|png|webp)
				ffmpeg -v error -y -i "video.$ext" \
					-vf "pad=h=ih+$(bc <<< "$last_ycord+($line_th/0.9)"):w=iw+4:x=-1:y=$(bc <<< "$last_ycord+($line_th/0.9)")-1:color=white,$drawtext" \
					-an "video-toptext.$ext"
			;;
			mp4|MP4)
				case "${file_type[1]}" in
					animation)
						ffmpeg -v error -y -i "video.$ext" \
							-vf "pad=h=$nh:y=$ypad_cord:color=white,$drawtext" \
							-an "video-toptext.$ext"
					;;
					video)
						ffmpeg -v error -y -i "video.$ext" \
							-vf "pad=h=$nh:y=$ypad_cord:color=white,$drawtext" \
							"video-toptext.$ext"
					;;
				esac
			;;
		esac
	else
		tw_c=$((tw_c+1))
		if [[ "$((tw_c%4))" == "0" ]] && [[ "$fs" -gt "8" ]]; then
			fs=$(bc <<< "$fs-($fs/4)")
			printf '%s' "$(tr '\n' ' ' <<< "$toptext")" > "$tts"
			line_th=$(ffmpeg -v 24 -hide_banner -f lavfi -i color \
				-vf "drawtext=$font:fontsize=$fs:textfile=$tts:y=print(th\,24)" \
				-vframes 1 -f null - 2>&1 | sed -n 1p | sed 's/\..*//')
		else
			toptext=$(fold -s -w $(bc <<< "(($tt_wc/2)+5)-$tw_c") <<< "$unfolded" | sed -e 's/ *$//g' -e 's/^ *//g' | sed '/^ *$/d' | sed '/^$/d')
		fi
		if [[ "$tw_c" -lt "30" ]]; then
			get_tw
		else
			return
		fi
	fi
}
get_tw
