toptext=$(sed "s/'/ʼ/g" <<< "${fn_arg[@]}") size=3
unfolded=$toptext tt_wc=$(wc -m <<< "$toptext")
res=($(ffprobe -v error -show_streams "video-$request_id.mp4" | sed -n -e 's/^width=\(.*\)/\1/p' -e 's/^height=\(.*\)/\1/p'))
fs=$(bc <<< "(${res[1]}/$size)/2")
ypad=$(bc <<< "${res[1]}/$size")
nh=$(bc <<< "${res[1]}+$ypad")
fontfile="$(realpath ~/.local/share/fonts)/futura.otf"
drawtext_lines() {
	for x in $(seq $nl -1 1); do
		line=$(sed -n ${x}p <<< "$toptext")
		ycord=$(bc <<< "($th*(($x-1)*1.5))+5")
		[[ "$x" == "$nl" ]] && last_ycord=$ycord
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
	w_diff=$(bc <<< "${res[0]}/$tw")
	if [[ "$w_diff" != "0" ]]; then
		drawtext_lines
		nh=$(bc <<< "${res[1]}+$last_ycord+($th*1.7)")
		ypad=$(bc <<< "$nh/$size")
		ffmpeg -y -i "video-$request_id.mp4" \
			-vf "pad=height=$nh:y=$(bc <<< "$last_ycord+($th*1.7)"):color=white,$drawtext" \
			-an "video-toptext-$request_id.mp4" 2>/dev/null
	else
		tw_c=$((tw_c+1))
		toptext=$(fold -s -w $(bc <<< "($tt_wc/$tw_c)+5") <<< "$unfolded")
		if [[ "$tw_c" -lt "10" ]]; then
			get_tw
		else
			return
		fi
	fi
}
get_tw
