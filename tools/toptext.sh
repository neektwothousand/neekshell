#!/bin/mksh
toptext=$1 size=3
unfolded=$toptext tt_wc=$(wc -m <<< "$toptext")
res=($(ffprobe -v error -show_streams "video-$request_id.mp4" | sed -n -e 's/^width=\(.*\)/\1/p' -e 's/^height=\(.*\)/\1/p'))
fs=$(bc <<< "(${res[1]}/$size)/2")
fontfile="$(realpath ~/.local/share/fonts)/futura.otf"
th=$(ffmpeg -v 24 -hide_banner -f lavfi -i color \
	-vf "drawtext=fontfile=$fontfile:fontsize=$fs:text=$toptext:y=print(th\,24)" \
	-vframes 1 -f null - 2>&1 | sed -n 1p | sed 's/\..*//')
line_th=$th
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
		if [[ "$x" == "$nl" ]]; then
			ycord=$(bc <<< "$ycord+($line_th/4)")
		else
			ycord=$(bc <<< "$ycord+($line_th/1.2)")
		fi
		printf '%s\n' "$ycord($x) res1: ${res[1]}"
		lines[$x]="drawtext=box=1:text=$line:fontfile=$fontfile:fontsize=$fs:y=$ycord:x=(w-tw)/2,"
	done
	last_ycord=$ycord
	drawtext=$(printf '%s' "${lines[@]}" | head -c -1)
	unset lines
}
get_tw() {
	tw=$(ffmpeg -v 24 -hide_banner -f lavfi -i color \
		-vf "drawtext=fontfile=$fontfile:fontsize=$fs:text=$toptext:x=print(tw\,24)" \
		-vframes 1 -f null - 2>&1 | sed -n 1p | sed 's/\..*//')
	nl=$(wc -l <<< "$toptext")
	w_diff=$(bc <<< "${res[0]}/$tw")
	if [[ "$w_diff" != "0" ]]; then
		drawtext_lines
		get_nh "$mode" "$nh" "text"
		ffmpeg -y -i "video-$request_id.mp4" \
			-vf "pad=height=$nh:y=$ypad_cord:color=white,$drawtext" \
			-an "video-toptext-$request_id.mp4" 2>/dev/null
	else
		tw_c=$((tw_c+1))
		if [[ "$tw_c" == "1" ]]; then
			fs=$(bc -l <<< "(${res[1]}/$size)/2.5" | sed 's/\..*//')
			th=$(ffmpeg -v 24 -hide_banner -f lavfi -i color \
				-vf "drawtext=fontfile=$fontfile:fontsize=$fs:text=$toptext:y=print(th\,24)" \
				-vframes 1 -f null - 2>&1 | sed -n 1p | sed 's/\..*//')
		else
			toptext=$(fold -s -w $(bc <<< "($tt_wc/$tw_c)+5") <<< "$unfolded")
		fi
		if [[ "$tw_c" -lt "15" ]]; then
			get_tw
		else
			return
		fi
	fi
}
get_tw
