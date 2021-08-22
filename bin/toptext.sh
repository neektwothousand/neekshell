toptext=$(sed "s/'/ʼ/g" <<< "${fn_arg[@]}") size=3
res=($(ffprobe -v error -show_streams "video-$request_id.mp4" | sed -n -e 's/^width=\(.*\)/\1/p' -e 's/^height=\(.*\)/\1/p'))
fs=$(bc <<< "(${res[1]}/$size)/2")
ypad=$(bc <<< "${res[1]}/$size")
nh=$(bc <<< "${res[1]}+$ypad")
fontfile="$(realpath ~/.local/share/fonts)/futura.otf"
drawtext_lines() {
 	planes=$(bc <<< "$ypad/$nl")
	for x in $(seq $nl -1 1); do
		line=$(sed -n ${x}p <<< "$toptext")
		ycord=$(bc <<< "($planes*($x-1))+($th/($nl^2))")
		lines[$x]="drawtext=box=1:text=$line:fontfile=$fontfile:fontsize=$fs:y=$ycord:x=(w-tw)/2,"
	done
	drawtext=$(printf '%s' "${lines[@]}" | head -c -1)
	unset lines
}
get_tw() {
	ffmpeg_out=$(ffmpeg -hide_banner -nostats -i "video-$request_id.mp4" \
		-vf "drawtext=fontfile=$fontfile:fontsize=$fs:text=$toptext:x=0+0*print(tw)" \
		-vframes 1 -f null - 2>&1)
	text_res=$(grep -A 2 '^Press' <<< "$ffmpeg_out" | sed '/Press/d')
	tw=$(sed -n 1p <<< "$text_res" | sed 's/\..*//')
	th=$(bc <<< "$fs/1.5")
	nl=$(wc -l <<< "$toptext")
	combined_th=$(bc <<< "($th*$nl)+25")
	w_diff=$(bc <<< "${res[0]}/$tw")
	if [[ "$w_diff" != "0" ]]; then
		if [[ "$combined_th" -ge "$ypad" ]]; then
			ypad=$(bc <<< "$ypad+($combined_th-$ypad)+25")
			nh=$(bc <<< "${res[1]}+$ypad")
		fi
		drawtext_lines
		ffmpeg -y -i "video-$request_id.mp4" \
			-vf "pad=height=$nh:y=$ypad:color=white,$drawtext" \
			-an "video-toptext-$request_id.mp4" 2>/dev/null
	else
		toptext=$(fold -s -w \
			$(bc <<< "$(wc -m <<< "$toptext")/(($tw/${res[0]})+1)") \
			<<< "$toptext")
		tw_c=$((tw_c+1))
		if [[ "$tw_c" -lt "5" ]]; then
			get_tw
		else
			return
		fi
	fi
}
get_tw
