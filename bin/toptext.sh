toptext=${fn_arg[@]} size=3
res=($(ffprobe -v error -show_streams "video-$request_id.mp4" | sed -n -e 's/^width=\(.*\)/\1/p' -e 's/^height=\(.*\)/\1/p'))
nh=$(bc <<< "${res[1]}+${res[1]}/$size")
fs=$(bc <<< "(${res[1]}/$size)/2")
ypad=$(bc <<< "${res[1]}/$size")
fontfile="$(realpath ~/.local/share/fonts)/futura.otf"
breakpoint() {
	if [[ "$s" -ge 4 ]]; then
		b=$(bc <<< "$s/2")
	else
		b=1
	fi
}
drawtext_lines() {
	y=1
	for x in $(seq $(wc -l <<< "$toptext") -1 1); do
		line=$(sed -n ${x}p <<< "$toptext")
		lines[$x]="drawtext=box=1:text=$line:fontfile=$fontfile:fontsize=$fs:y=($ypad-th)/$(bc <<< "$y*1.5"):x=(w-tw)/2,"
		y=$(bc <<< "$y+1")
	done
	drawtext=$(printf '%s' "${lines[@]}" | head -c -1)
}
get_tw() {
	ffmpeg_out=$(ffmpeg -hide_banner -nostats -i "video-$request_id.mp4" \
		-vf "drawtext=fontfile=$fontfile:fontsize=$fs:text=$toptext:x=0+0*print(tw):y=0+0*print(th)" \
		-vframes 1 -f null - 2>&1)
	text_res=$(grep -A 2 '^Press' <<< "$ffmpeg_out" | sed '/Press/d')
	tw=$(sed -n 1p <<< "$text_res" | sed 's/\..*//')
	th=$(sed -n 2p <<< "$text_res" | sed 's/\..*//')
	th=$(bc <<< "$th*$(wc -l <<< "$toptext")")
	w_diff=$(bc <<< "${res[0]}/$tw")
	if [[ "$w_diff" != "0" ]]; then
		if [[ "$th" -gt "$ypad" ]]; then
			h_diff=$(bc <<< "($th-$ypad)+20")
			nh=$(bc <<< "$nh+$h_diff")
			ypad=$(bc <<< "$ypad+$h_diff")
			drawtext_lines
		fi
		ffmpeg -y -i "video-$request_id.mp4" \
			-vf "pad=height=$nh:y=$ypad:color=white,$drawtext" \
			-acodec copy "video-toptext-$request_id.mp4" 2>/dev/null
	else
		for x in $(seq $(wc -l <<< "$toptext")); do
			[[ $x == 1 ]] && y=1 || y=$((y+2))
			line=$(sed -n "${y}p" <<< "$toptext")
			if [[ "$(grep " " <<< "$line")" ]]; then
				s=$(sed "s/[^ ]//g" <<< "$line" | wc -m)
				breakpoint
				toptext=$(sed "${y}s/ /\n/${b}" <<< "$toptext")
			else
				s=$(wc -m <<< "$line")
				breakpoint
				toptext=$(sed "${y}s/\(.\)/\1\n/${b}" <<< "$toptext")
			fi
		done
		tw_c=$((tw_c+1))
		if [[ "$tw_c" -lt "5" ]]; then
			drawtext_lines
			get_tw
		else
			return
		fi
	fi
}
get_tw
