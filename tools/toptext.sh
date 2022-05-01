#!/bin/mksh
toptext=$1 mode=$2 media=$3 size=3 xpad_cord=0
case "$mode" in
	top|bottom)
		nw=0
		max_fs_resize=2
	;;
	*)
		max_fs_resize=3
	;;
esac
tw_s=0
unfolded=$toptext tt_wc=$(wc -m <<< "$toptext")
res=($(ffprobe -v error -show_streams "$media" \
	| sed -n -e 's/^width=\(.*\)/\1/p' -e 's/^height=\(.*\)/\1/p'))
fs=$(bc <<< "(${res[1]}/$size)/2")
tts="toptext-start"
printf '%s' "$(tr '\n' ' ' <<< "$toptext")" > "$tts"
if [[ "$(grep -P '[\p{Han}]' <<< "$toptext")" ]]; then
	font="font=Noto Sans CJK HK"
else
	font="fontfile=$(realpath ~/.local/share/fonts)/futura.otf"
fi
get_line_th() {
	ffmpeg -v 24 -hide_banner -f lavfi -i color \
		-vf "drawtext=$font:fontsize=$fs:textfile=$1:y=print(th\,24)" \
		-vframes 1 -f null - 2>&1 | sed -n 1p | sed 's/\..*//'
}
line_th=$(get_line_th "$tts")
get_nh() {
	case "$mode" in
	top)
		nh=$(bc <<< "${res[1]}+$last_ycord+($line_th/1.4)")
		ypad_cord=$(bc <<< "$last_ycord+($line_th/1.4)")
	;;
	bottom)
		nh=$(bc <<< "$last_ycord+($line_th/1.4)")
		ypad_cord=0
	;;
	left|right)
		nh=${res[1]}
		ypad_cord=$(bc <<< "$last_ycord+($line_th/1.4)")
	;;
	esac
}
get_nw() {
	case "$mode" in
		left|right)
			pad_w=$(bc <<< "($tw*1.2)+$tw_s" | sed "s/\..*//")
			if [[ "$pad_w" -gt "$((${res[0]}/3))" ]]; then
				pad_w=$(bc <<< "(${res[0]}/3)+((${res[0]}/30)/2)")
			fi
		;;
	esac
	case "$mode" in
		left)
			nw=$(bc <<< "${res[0]}+$pad_w")
			xpad_cord=$pad_w
		;;
		right)
			nw=$(bc <<< "${res[0]}+$pad_w")
			xpad_cord=0
		;;
		top|bottom)
			nw=${res[0]}
			xpad_cord=0
		;;
	esac
}
drawtext_lines() {
	case "$mode" in
	top|left|right)
		ycord=0
	;;
	bottom)
		ycord=${res[1]}
	;;
	esac
	for x in $(seq $nl -1 1); do
		line=$(sed -n ${x}p <<< "$(tac <<< "$toptext")")
		tf[$x]="toptext-$x"
		printf '%s' "$line" > "${tf[$x]}"
		if [[ "$x" == "$nl" ]]; then
			line_th=$(get_line_th "${tf[$x]}")
			line_th=$((line_th+(line_th/2)))
			case "$mode" in
			top|left|right)
				ycord=$(bc <<< "$ycord+($line_th/3.4)")
			;;
			bottom)
				ycord=$(bc <<< "$ycord+($line_th/2.8)")
			;;
			esac
		else
			line_th=$(get_line_th "${tf[$((x+1))]}")
			line_th=$((line_th+(line_th/2)))
			ycord=$(bc <<< "$ycord+($line_th/1.2)")
		fi
		case "$mode" in
			top|bottom)
				lines[$x]="drawtext=box=1:textfile=${tf[$x]}:$font:fontsize=$fs:y=$ycord:x=(w-tw)/2,"
			;;
			left|right)
				case "$mode" in
					left)
						xcord="(${res[0]}/30)"
					;;
					right)
						xcord="(w-(w/30))-$tw"
					;;
				esac
				lines[$x]="drawtext=box=1:textfile=${tf[$x]}:$font:fontsize=$fs:y=$ycord:x=$xcord,"
			;;
		esac
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
	case "$mode" in
		top|bottom)
			w_diff=$(bc <<< "${res[0]}/$tw")
		;;
		left|right)
			get_nw
			w_diff=$(bc <<< "$pad_w/($tw+(${res[0]}/30))")
		;;
	esac
	if [[ "$w_diff" != "0" ]]; then
		drawtext_lines
		line_th=$(get_line_th "$tts")
		line_th=$((line_th+line_th))
		get_nh
		case "$ext" in
			jpg|jpeg|png|webp)
				case "$mode" in
				bottom|left|right)
					ypad_cord=1
				;;
				top)
					ypad_cord=$((ypad_cord-1))
				;;
				esac
				ffmpeg -v error -y -i "$media" \
					-vf "pad=h=$nh:w=$nw:x=$xpad_cord:y=$ypad_cord:color=white,$drawtext" \
					-f image2pipe -an - | \
					ffmpeg -v error -y -f image2pipe \
						-i - -filter:v "crop=iw-4:ih-1" "toptext.$ext"
			;;
			mp4|MP4)
				case "${file_type[1]}" in
					animation)
						ffmpeg -v error -y -i "$media" \
							-vf "pad=h=$nh:w=$nw:y=$ypad_cord:x=$xpad_cord:color=white,$drawtext" \
							-an "toptext.$ext"
					;;
					video)
						ffmpeg -v error -y -i "$media" \
							-vf "pad=h=$nh:y=$ypad_cord:color=white,$drawtext" \
							"toptext.$ext"
					;;
				esac
			;;
		esac
	else
		k=$((k+1))
		if [[ "$k" -lt "$max_fs_resize" ]]; then
			fs=$(bc <<< "$fs/1.5")
			printf '%s' "$(tr '\n' ' ' <<< "$toptext")" > "$tts"
			line_th=$(get_line_th "$tts")
		elif [[ ! "$to_fold" ]]; then
			p=$((p+1))
			tw_s=$(bc <<< "$tw_s+(${res[0]}/30)")
			[[ "$p" -gt "30" ]] && to_fold=true
		else
			f=$((f+1))
			toptext=$(fold -s -w $(bc <<< "(($tt_wc/2)+5)-$f") <<< "$unfolded" | sed -e 's/ *$//g' -e 's/^ *//g' | sed '/^ *$/d' | sed '/^$/d')
		fi
		if [[ "$k" -lt "160" ]]; then
			get_tw
		else
			return
		fi
	fi
}
get_tw
