video_jpg() {
	if [[ "${file_type[1]}" == "video" ]]; then
		audio_c="-c:a aac"
	elif [[ "${file_type[1]}" == "animation" ]]; then
		video_id[1]=${animation_id[1]}
		audio_c="-an"
	fi
	case "$1" in
		video)
			audio_c="-c:a aac"
		;;
		animation)
			audio_c="-an"
		;;
	esac
	case "$2" in
		animation)
			video_id[1]=${animation_id[1]}
		;;
		videosticker)
			video_id[1]=${sticker_id[1]}
		;;
	esac
	loading 1
	tg_method get_file "${video_id[1]}"
	file_path="${TELEAPI_BASE_URL}/file/bot$TOKEN/$(jshon -Q -e result -e file_path -u <<< "$curl_result")"
	video_info=$(ffprobe -v error \
		-show_entries stream=sample_rate,bit_rate,duration,width,height,r_frame_rate \
		-of default=noprint_wrappers=1 "$file_path")
	res[0]=$(sed -n 's/^width=//p' <<< "$video_info")
	res[1]=$(sed -n 's/^height=//p' <<< "$video_info")
	res[0]=$(bc <<< "${res[0]}/$factor")
	res[1]=$(bc <<< "${res[1]}/$factor")
	[[ "$((${res[0]}%2))" -eq "0" ]] || res[0]=$((${res[0]}-1))
	[[ "$((${res[1]}%2))" -eq "0" ]] || res[1]=$((${res[1]}-1))
	if [[ "${file_type[1]}" == "video" ]]; then
		br=$(sed -n 's/^bit_rate=//p' <<< "$video_info" | head -n 1)
		sr=$(sed -n 's/^sample_rate=//p' <<< "$video_info" | head -n 1)
		if [[ "$br" ]] && [[ "$sr" ]]; then
			srs=(24000 16000 11025 7350)
			y=0 ; for x in ${srs[@]}; do
				if [[ "$sr" == "${srs[$y]}" ]] \
				&& [[ "$y" != "3" ]]; then
					sr=${srs[$((y+1))]}
					break
				else
					y=$((y+1))
				fi
				if [[ "$y" == "3" ]]; then
					sr=${srs[0]}
				fi
			done
			audio_c="$audio_c -b:a $(bc <<< "$br/2") -ar $sr"
		fi
	fi
	ffmpeg -v error -i "$file_path" \
		-vf "scale=${res[0]}:${res[1]}" -sws_flags fast_bilinear \
		-crf 50 $audio_c "video-low.mp4"
	loading 2
	if [[ "${file_type[1]}" == "video" ]]; then
		video_id="@video-low.mp4"
		tg_method send_video upload
	else
		animation_id="@video-low.mp4"
		tg_method send_animation upload
	fi
	loading 3
	rm -f -- "video.$ext" "video-low.mp4"
}
bot_chat_send_message() {
	chat_id=$1
	bot_chat_db="${bot_chat_dir}${bot_chat_id}_db"
	if [[ ! -d "$bot_chat_db" ]]; then
		mkdir "$bot_chat_db"
	fi
	bot_user_db="$bot_chat_db/$1"
	if [[ ! -d "$bot_user_db" ]]; then
		mkdir "$bot_user_db"
	fi
	if [[ "${message[1]}" ]]; then
		reply_id=$(cat "$bot_user_db/$(jshon -Q -e date -u <<< "${message[1]}")")
	fi
	tg_method $method
	printf '%s' "$(jshon -Q -e result -e message_id -u <<< "$curl_result")" \
		> "$bot_user_db/$(jshon -Q -e result -e date -u <<< "$curl_result")"
}
twd() {
	if [[ "$1" != "exit" ]]; then
		cd "$tmpdir"
		twd_id=$RANDOM
		twd_dir="twd_$twd_id"
		mkdir "$twd_dir" && cd "$twd_dir"
	else
		cd "$tmpdir" \
			&& rm -rf "twd_$twd_id/" \
			&& cd "$basedir"
	fi
}
command_help() {
	case "$1" in
		bot_admin)
			help_dir="$basedir/help/bot_admin"
		;;
		chat_admin)
			help_dir="$basedir/help/chat_admin"
		;;
		*)
			help_dir="$basedir/help"
		;;
	esac
	text_id=$(cat "$help_dir/$(sed "s/^.//" <<< "$command")")
	get_reply_id self
}
case_command() {
	case "$command" in
		"!chat")
			if [[ "$chat_type" = "private" ]] || [[ $(is_status admins) ]] ; then
				get_reply_id self
				case "${arg[0]}" in
					"create")
						[[ ! -d "$bot_chat_dir" ]] && mkdir -p "$bot_chat_dir"
						if [[ "$(dir "$bot_chat_dir" | grep -o -- "$bot_chat_user_id")" = "" ]]; then
							file_bot_chat="$bot_chat_dir$bot_chat_user_id"
							[[ ! -e "$file_bot_chat" ]] && printf '%s\n' "users: " > "$file_bot_chat"
							text_id="your chat id: \"$bot_chat_user_id\""
						else
							text_id="you've already an existing chat"
						fi
					;;
					"delete")
						if [[ "$(dir "$bot_chat_dir" | grep -o -- "$bot_chat_user_id")" != "" ]]; then
							file_bot_chat="$bot_chat_dir$bot_chat_user_id"
							rm "$file_bot_chat"
							text_id="\"$bot_chat_user_id\" deleted"
						else
							text_id="you have not created any chat yet"
						fi
					;;
					"join"|"join"*)
						if [[ "$(grep -r -- "$bot_chat_user_id" "$bot_chat_dir")" = "" ]]; then
							case "${arg[0]}" in
								"join")
									if [[ "$chat_type" = "private" ]]; then
										text_id="Select chat to join:"
										num_bot_chat=$(ls -1 "$bot_chat_dir" | grep -v "db$" | wc -l)
										list_bot_chat=$(ls -1 "$bot_chat_dir" | grep -v "db$")
										for j in $(seq 0 $((num_bot_chat - 1))); do
											button_text[$j]=$(sed -n $((j+1))p <<< "$list_bot_chat")
										done
									elif [[ "$chat_type" != "private" ]]; then
										if [[ $(is_status admins) ]]; then
											join_chat=${arg[1]}
											sed -i "s/\(users: \)/\1$chat_id /" $bot_chat_dir"$join_chat"
											text_id="joined $join_chat"
										else
											markdown=("<code>" "</code>")
											parse_mode=html
											text_id="Access denied"
										fi
									fi
								;;
								"join"*)
									if [[ "$chat_type" = "private" ]]; then
										join_chat=$(sed 's/^join//' <<< "${arg[0]}")
										sed -i "s/\(users: \)/\1$user_id /" \
											$bot_chat_dir"$join_chat"
										text_id="joined $join_chat"
									fi
								;;
							esac
						else
							text_id="you're already in an existing chat"
						fi
					;;
					"leave")
						if [[ "$(grep -r -- "$bot_chat_user_id" "$bot_chat_dir")" != "" ]]; then
							if [[ "$chat_type" = "private" ]]; then
								leave_chat=$(grep -r -- "$bot_chat_user_id" "$bot_chat_dir" | cut -d : -f 1 | cut -f 3 -d '/')
								text_id="Select chat to leave:"
								sed -i "s/$chat_id //" $bot_chat_dir"$leave_chat"
								text_id="$leave_chat is no more"
							elif [[ "$chat_type" != "private" ]]; then
								if [[ $(is_status admins) ]]; then
									leave_chat=${arg[1]}
									sed -i "s/$chat_id //" $bot_chat_dir"$leave_chat"
									text_id="$leave_chat is no more"
								else
									markdown=("<code>" "</code>")
									text_id="Access denied"
								fi
							fi
						else
							text_id="you are not in any chat yet"
						fi
					;;
					"users")
						if [[ "$(grep -r -- "$bot_chat_user_id" "$bot_chat_dir")" != "" ]]; then
							text_id="number of active users: $(grep -r -- "$bot_chat_user_id" "$bot_chat_dir" | sed 's/.*:\s//' | tr ' ' '\n' | sed '/^$/d' | wc -l)"
						else
							text_id="you are not in any chat yet"
						fi
					;;
					"list")
						text_id=$(
							for c in $(seq "$(ls -1 "$bot_chat_dir" | grep -v "db$" | wc -l)"); do
								bot_chat_id=$(ls -1 "$bot_chat_dir" | grep -v "db$" | sed -n "${c}"p)
								bot_chat_users=$(sed 's/.*:\s//' "$bot_chat_dir$bot_chat_id" | tr ' ' '\n' | sed '/^$/d' | wc -l)
								printf '%s\n' "chat: $bot_chat_id users: $bot_chat_users"
							done
						)
						[[ "$text_id" = "" ]] && text_id="no chats found"
					;;
					*)
						command_help
					;;
				esac
				tg_method send_message
			fi
		;;
		"!convert")
			[[ -e "$basedir/powersave" ]] && return
			if [[ "${message_id[1]}" ]] && [[ "${arg[0]}" ]]; then
				twd
				get_reply_id reply
				if [[ "${sticker_is_video[1]}" ]]; then
					file_type[1]=animation
					animation_id[1]=${sticker_id[1]}
				fi
				case "${file_type[1]}" in
					video|animation)
						tg_method get_file "${animation_id[1]}"
						file_path="$(jshon -Q -e result -e file_path -u <<< "$curl_result")"
						remote_file_path="${TELEAPI_BASE_URL}/file/bot$TOKEN/$file_path"
						input_codecs=$(ffprobe -v error \
							-show_streams "$remote_file_path" | grep "^codec_name")
						case "${file_type[1]}" in
							video) media_id=${video_id[1]} ;;
							animation) media_id=${animation_id[1]} ;;
						esac
						case "${arg[0]}" in
							animation|mp4|h264|h265|hevc)
								cpu_model=$(lscpu -J | jshon -Q -e lscpu -e 6 -e data -u)
								if [[ "$cpu_model" == "Cortex-A72" ]] \
								&& [[ "$(grep "h265\|hevc" <<< "${arg[0]}")" ]]; then
									return
								fi
								loading 1
								out_file="convert.mp4"
								crf=$(grep -o "^[0-9]*" <<< "${arg[1]}")
								if [[ "$crf" ]]; then
									if [[ "$crf" -lt "51" ]] || [[ "$crf" -ge "0" ]]; then
										crf="-crf $crf"
									fi
								fi
								if [[ ! "$crf" ]] && [[ ! "$(grep "h265\|hevc" <<< "${arg[0]}")" ]] \
								&& [[ "$(grep "^codec_name=h264$" <<< "$input_codecs")" ]]; then
									out_vcodec=copy
								else
									case "${arg[0]}" in
										h265|hevc)
											out_vcodec=libx265
										;;
										*)
											out_vcodec=h264
										;;
									esac
								fi
								case "${arg[0]}" in
									animation)
										ffmpeg -v error -i "$remote_file_path" \
											-pix_fmt yuv420p \
											-vcodec $out_vcodec $crf -an "$out_file"
									;;
									*)
										ffmpeg -v error -i "$remote_file_path" \
											-pix_fmt yuv420p \
											-vcodec $out_vcodec $crf "$out_file"
									;;
								esac
								loading 2
								animation_id="@$out_file"
								tg_method send_animation upload
							;;
							audio|mp3|ogg)
								loading 1
								case "${arg[0]}" in
									mp3|ogg)
										ext=${arg[0]}
									;;
									*)
										ext=mp3
									;;
								esac
								out_file="convert.$ext"
								case "$ext" in
									mp3)
										out_acodec=libmp3lame
									;;
									ogg)
										out_acodec=libvorbis
									;;
								esac
								ffmpeg -v error -i "$remote_file_path" -vn -acodec $out_acodec "$out_file"
								loading 2
								audio_id="@$out_file"
								tg_method send_audio upload
							;;
						esac
						case "${arg[0]}" in
							png|jpg|jpeg|photo)
								case "${arg[0]}" in
									png) ext=png ;;
									jpg|jpeg) ext=jpg ;;
									photo) ext=jpg ;;
								esac
								ffmpeg -v error -ss 0.1 -i "$remote_file_path" \
									-vframes 1 -f image2 "convert.$ext"
								photo_id="@convert.$ext"
								tg_method send_photo upload
							;;
						esac
					;;
					photo|sticker)
						case "${file_type[1]}" in
							photo) media_id=${photo_id[1]} ;;
							sticker) media_id=${sticker_id[1]} ;;
						esac
						tg_method get_file "${media_id}"
						file_path="$(jshon -Q -e result -e file_path -u <<< "$curl_result")"
						remote_file_path="${TELEAPI_BASE_URL}/file/bot$TOKEN/$file_path"
						case "${arg[0]}" in
							png|jpg|avif|hei[cf]|webp)
								loading 1
								out_file="convert.${arg[0]}"
								err_out=$(ffmpeg -v error -i "$remote_file_path" "$out_file")
								loading 2
								document_id="@$out_file"
								tg_method send_document upload
							;;
							file|document)
								loading 1
								out_file="convert.${arg[0]}"
								wget -q -O "$out_file" "$remote_file_path"
								document_id="@$out_file"
								tg_method send_document upload
							;;
						esac
					;;
					audio)
						tg_method get_file "${audio_id[1]}"
						file_path="$(jshon -Q -e result -e file_path -u <<< "$curl_result")"
						remote_file_path="${TELEAPI_BASE_URL}/file/bot$TOKEN/$file_path"
						case "${arg[0]}" in
							mp3)
								out_file="convert.mp3"
								loading 1
								err_out=$(ffmpeg -v error -i "$file_path" \
									-vn -acodec libmp3lame -b:a 320k "$out_file")
								audio_id="@$out_file"
								loading 2
								tg_method send_audio upload
							;;
							opus|vorbis|voice)
								out_file="convert.ogg"
								loading 1

								case "${arg[0]}" in
									opus|voice)
										acodec="libopus"
									;;
									vorbis)
										acodec="libvorbis"
									;;
								esac

								err_out=$(ffmpeg -v error -i "$file_path" \
									-vn -acodec $acodec "$out_file")

								loading 2
								if [[ "${arg[0]}" == "voice" ]]; then
									voice_id="@$out_file"
									tg_method send_voice upload
								else
									document_id="@$out_file"
									tg_method send_document upload
								fi
							;;
						esac
					;;
				esac
				loading 3
				rm -f "$out_file"
				if [[ "$(jshon -Q -e ok -u <<< "$curl_result")" != "false" ]] \
				&& [[ "$err_out" ]]; then
					text_id=$err_out
					tg_method send_message
				fi
			fi
		;;
		"!custom")
			get_reply_id self
			if [[ "${arg[0]}" ]] && [[ "${arg[1]}" ]]; then
				if [[ "$(grep "^!" <<< "${arg[0]}")" ]]; then
					user_command=${arg[0]}
				else
					user_command="!${arg[0]}"
				fi
				user_command=$(tr -d '/' <<< "$user_command")
				
				[[ ! -d custom_commands/user_generated/ ]] && \
					mkdir custom_commands/user_generated/
				
				printf '%s\n' "$(head -n 1 <<< "$user_text" \
					| cut -f 3- -d ' ' \
					| sed "/^$/d" ; sed 1d <<< "$user_text")" \
						> "custom_commands/user_generated/$chat_id-$user_command"
				text_id="$user_command set"
			else
				command_help
			fi
			tg_method send_message
		;;
		"!d"|"!dice")
			get_reply_id self
			case "${arg[0]}" in
				[0-9]*|[0-9]*"*"[0-9]*)
					if [[ "$(grep "*" <<< "$user_text")" != "" ]]; then
						normaldice=$(sed "s/$command//" <<< "$user_text" | cut -d "*" -f 1)
						mul=$(sed "s/$command//" <<< "$user_text" | cut -d "*" -f 2)
					else
						normaldice=$(sed "s/$command//" <<< "$user_text")
						mul=1
					fi
					for x in $(seq "$mul"); do
						chars=$(( $(wc -m <<< "$normaldice") - 1 ))
						result[$x]=$(bc <<< "($(cat /dev/urandom | tr -dc '[:digit:]' 2>/dev/null | head -c $chars) % $normaldice)+1")
					done
					text_id=${result[*]}
					markdown=("<code>" "</code>")
					parse_mode=html
					tg_method send_message
				;;
				*)
					command_help
					tg_method send_message
				;;
			esac
		;;
		"!ffprobe")
			if [[ "${message_id[1]}" ]]; then
				case "${file_type[1]}" in
					animation)
						media_id=${animation_id[1]}
					;;
					photo)
						media_id=${photo_id[1]}
					;;
					video)
						media_id=${video_id[1]}
					;;
					sticker)
						media_id=${sticker_id[1]}
					;;
				esac
				if [[ "$media_id" ]]; then
					get_reply_id self
					tg_method get_file "$media_id"
					file_path="$(jshon -Q -e result -e file_path -u <<< "$curl_result")"
					remote_file_path="${TELEAPI_BASE_URL}/file/bot$TOKEN/$file_path"
					text_id=$(ffprobe "$remote_file_path" 2>&1 | grep -v '^  lib' | sed '1,5d' | sed 's/^  //')
					markdown=("<code>" "</code>")
					parse_mode=html
					tg_method send_message
				fi
			fi
		;;
		"!flag")
			[[ -e "$basedir/powersave" ]] && return
			if [[ "${message_id[1]}" ]] && [[ "${arg[0]}" ]] \
				&& [[ "${file_type[1]}" == "photo" ]]; then

				case "${arg[0]}" in
					[1-9]|[1-9][0-9]|[1-9][0-9][0-9])
						get_reply_id self
						twd
						media_id=${photo_id[1]}
						tg_method get_file "$media_id"
						file_path="$(jshon -Q -e result -e file_path -u <<< "$curl_result")"
						remote_file_path="${TELEAPI_BASE_URL}/file/bot$TOKEN/$file_path"
						text_id=$("$basedir"/tools/flag/flag.sh "$file_path" "${arg[0]}" "flag.png")
						photo_id=@flag.png
						tg_method send_message
						tg_method send_photo upload
						rm -vf flag.png
					;;
				esac
			fi
		;;
		"!fortune")
			if [[ "${arg[0]}" = "" ]]; then
				text_id=$(/usr/bin/fortune fortunes paradoxum goedel | tr '\n' ' ' | awk '{$2=$2};1')
			else
				text_id=$(/usr/bin/fortune "${arg[0]}" | tr '\n' ' ' | awk '{$2=$2};1')
			fi
			if [[ "$text_id" != "" ]]; then
				get_reply_id any
				tg_method send_message
			else
				command_help
				tg_method send_message
			fi
		;;
		"!gayscale"|"!gs")
			if [[ "${user_id[1]}" = "" ]]; then
				gs_id=$user_id
				gs_fname=$user_fname
			else
				gs_id=${user_id[1]}
				gs_fname=${user_fname[1]}
			fi
			[[ ! -d "$basedir/.lock+/gs/" ]] && mkdir -p "$basedir/.lock+/gs/"
			lockfile="$basedir/.lock+/gs/$gs_id-lock"
			# check if it's younger than one day
			lock_age=$(bc <<< "$(date +%s) - $(stat -c "%W" $lockfile)")
			if [[ -e "$lockfile" ]] && [[ "$lock_age" -lt "86400" ]]; then
				gs_perc=$(grep "^gs: " "$basedir/db/users/$gs_id" | sed 's/gs: //')
				if [[ $gs_perc -gt 9 ]]; then
					for x in $(seq $((gs_perc/10))); do
						rainbow="🏳️‍🌈${rainbow}"
					done
				fi
				text_id="$gs_fname is ${gs_perc}% gay $rainbow"
			else
				rm -f "$lockfile"
				get_chat_id=$gs_id
				tg_method get_chat
				gs_info="$user_fname $user_lname $(jshon -Q -e result -e bio -u <<< "$curl_result")"
				if [[ "$(grep 'admin\|bi\|gay\|🏳️‍🌈' <<< "$gs_info")" != "" ]]; then
					gs_perc=$(((RANDOM % 51) + 50))
				else
					gs_perc=$((RANDOM % 101))
				fi
				if [[ $gs_perc -gt 9 ]]; then
					for x in $(seq $((gs_perc/10))); do
						rainbow="🏳️‍🌈${rainbow}"
					done
				fi
				text_id="$gs_fname is ${gs_perc}% gay $rainbow"
				prev_gs=$(grep "^gs: " "$basedir/db/users/$gs_id" | sed 's/gs: //')
				if [[ "$prev_gs" = "" ]]; then
					printf '%s\n' "gs: 0" >> "$basedir/db/users/$gs_id"
				fi
				sed -i "s/^gs: .*/gs: ${gs_perc}/" "$basedir/db/users/$gs_id"
				touch "$lockfile"
			fi
			get_reply_id any
			tg_method send_message
		;;
		"!g"[tb]"t")
			[[ -e "$basedir/powersave" ]] && return
			if [[ "${message_id[1]}" != "" ]]; then
				twd
				get_reply_id reply
				case "${file_type[1]}" in
					animation|photo|video|sticker)
						case "${file_type[1]}" in
							animation)
								media_id=${animation_id[1]}
							;;
							video)
								media_id=${video_id[1]}
							;;
							photo)
								media_id=${photo_id[1]}
							;;
							sticker)
								media_id=${sticker_id[1]}
							;;
						esac
						file_path=$(curl -s "${TELEAPI}/getFile" \
							--form-string "file_id=$media_id" \
								| jshon -Q -e result -e file_path -u)
						ext=$(sed 's/.*\.//' <<< "$file_path")
						toptext=$(sed -e "s/$(head -n 1 <<< "$user_text" \
							| cut -f 1 -d ' ') //" -e "s/,/\\\,/g" <<< "$user_text")
						loading 1
						case "$command" in
							"!gtt") mode=top ;;
							"!gbt") mode=bottom ;;
						esac
						remote_file_path="${TELEAPI_BASE_URL}/file/bot$TOKEN/$file_path"
						source "$basedir/tools/toptext.sh" \
							"$toptext" "$mode" "$remote_file_path"

						loading 2
						case "${file_type[1]}" in
							animation)
								animation_id="@toptext.mp4"
								tg_method send_animation upload
							;;
							video)
								video_id="@toptext.mp4"
								tg_method send_video upload
							;;
							photo)
								photo_id="@toptext.png"
								tg_method send_photo upload
							;;
							sticker)
								sticker_id="@toptext.webp"
								tg_method send_sticker upload
							;;
						esac
						loading 3
					;;
				esac
			fi
		;;
		"!jpg")
			[[ -e "$basedir/powersave" ]] && return
			if [[ "${message_id[1]}" != "" ]]; then
				twd
				get_reply_id reply
				case "${arg[0]}" in
					[1-9])
						factor=$((2+${arg[0]}))
					;;
					*)
						factor=2
					;;
				esac
				case "${file_type[1]}" in
					text)
						text_id=$("$basedir/tools/jpg" "${user_text[1]}")
						tg_method send_message
					;;
					photo)
						tg_method get_file "${photo_id[1]}"
						remote_file_path="${TELEAPI_BASE_URL}/file/bot$TOKEN/$(jshon -Q -e result -e file_path -u <<< "$curl_result")"
						ext=$(sed 's/.*\.//' <<< "$remote_file_path")
						if [[ "$(grep "png\|jpg\|jpeg" <<< "$ext")" != "" ]]; then
							case "$ext" in
								png)
									convert "$remote_file_path" "pic.jpg"
									ext=jpg
								;;
								jpg|jpeg)
									wget -q -O "pic.jpg" "$remote_file_path"
								;;
							esac
							res=($(ffprobe -v error -show_streams "pic.$ext" \
								| sed -n -e 's/^width=\(.*\)/\1/p' -e 's/^height=\(.*\)/\1/p'))
							magick "pic.$ext" -resize \
								$(printf '%.0f\n' \
									"$(bc -l <<< "${res[0]}/$factor")")x$(printf '%.0f\n' \
										"$(bc -l <<< "${res[1]}/$factor")") "pic.$ext"
							magick "pic.$ext" -quality 4 "pic.$ext"
							photo_id="@pic.$ext"
							tg_method send_photo upload
							rm "pic.$ext"
						fi
					;;
					sticker)
						if [[ "${sticker_is_animated[1]}" != "true" ]] \
						&& [[ "${sticker_is_video[1]}" != "true" ]]; then
							tg_method get_file "${sticker_id[1]}"
							remote_file_path="${TELEAPI_BASE_URL}/file/bot$TOKEN/$(jshon -Q -e result -e file_path -u <<< "$curl_result")"
							res=($(ffprobe -v error -show_streams "$remote_file_path" \
								| sed -n -e 's/^width=\(.*\)/\1/p' -e 's/^height=\(.*\)/\1/p'))
							magick "$remote_file_path" "sticker.jpg"
							magick "sticker.jpg" -resize \
								$(bc <<< "${res[0]}/$factor")x$(bc <<< "${res[1]}/$factor") \
									"sticker.jpg"
							magick "sticker.jpg" -quality 4 "sticker.jpg"
							magick "sticker.jpg" -resize 512x512 "sticker.jpg"
							magick "sticker.jpg" "sticker.webp"

							sticker_id="@sticker.webp"
							tg_method send_sticker upload
							rm -f "sticker.webp" "sticker.jpg"
						elif [[ "${sticker_is_video[1]}" == "true" ]]; then
							video_jpg animation videosticker
						fi
					;;
					video|animation)
						video_jpg ${file_type[1]}
					;;
					audio|voice)
						if [[ "${file_type[1]}" == "voice" ]] then
							audio_id[1]=${voice_id[1]}
						fi
						tg_method get_file "${audio_id[1]}"
						remote_file_path="${TELEAPI_BASE_URL}/file/bot$TOKEN/$(jshon -Q -e result -e file_path -u <<< "$curl_result")"
						ext=$(sed 's/.*\.//' <<< "$remote_file_path")
						wget -q -O "audio.$ext" "$remote_file_path"
						loading 1
						audio_info=$(ffprobe -v error \
							-show_entries stream=sample_rate,bit_rate \
							-of default=noprint_wrappers=1 "$remote_file_path")
						br=$(sed -n 's/^bit_rate=//p' <<< "$audio_info" | head -n 1)
						if [[ "$br" == "N/A" ]]; then
							br=128000
						fi
						sr=$(sed -n 's/^sample_rate=//p' <<< "$audio_info" | head -n 1)
						srs=(24000 16000 11025 7350)
						y=0 ; for x in ${srs[@]}; do
							if [[ "$sr" == "${srs[$y]}" ]] \
							&& [[ "$y" != "3" ]]; then
								sr=${srs[$((y+1))]}
								break
							else
								y=$((y+1))
							fi
							if [[ "$y" == "3" ]]; then
								sr=${srs[0]}
							fi
						done
						ffmpeg -v error \
							-i "audio.$ext" -vn -acodec aac \
							-b:a $(bc <<< "$br/$factor") \
							-ar $sr \
							-strict -2 "audio-jpg.aac"
						loading 2
						audio_id="@audio-jpg.aac"
						tg_method send_audio upload
						loading 3
						rm -f "audio.$ext" "audio-jpg.aac"
					;;
				esac
			else
				command_help
				tg_method send_message
			fi
		;;
		"!json")
			twd
			update_id="${message_id}${user_id}"
			jshon -Q <<< "$input" > "$update_id.json"
			document_id="@$update_id.json"
			get_reply_id any
			tg_method send_document upload
			rm "$update_id.json"
		;;
		"!me")
			if [[ "${arg[0]}" ]]; then
				text_id="> $user_fname $(sed "s/^.$(tail -c +2 <<< "$command") //" <<< "$user_text")"
				tg_method send_message
				to_delete_id=$message_id
				tg_method delete_message
			else
				command_help
				tg_method send_message
			fi
		;;
		"!my")
			get_reply_id self
			case "${arg[0]}" in
				gs|gayscale)
					top_info="gs"
				;;
				*)
					command_help
					tg_method send_message
					return
				;;
			esac
			user_info=$(grep "^fname\|^lname\|^$top_info" "$file_user")
			if [[ "$top_info" == "totalrep" ]]; then
				p_rep_list=$(grep "^rep" "$file_user")
				for x in $(seq $(wc -l <<< "$p_rep_list")); do
					p_rep_fname=$(grep '^fname' "$basedir/db/users/$(sed -n ${x}p <<< "$p_rep_list" | sed -e "s/^rep-//" -e "s/:.*//")" \
						| cut -f 2- -d ' ' | sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g')
					p_rep=$(sed -n ${x}p <<< "$p_rep_list" | sed "s/^.*: //")
					p_user_entry[$x]="$p_rep from $p_rep_fname"
				done
			fi
			user_top=$(grep "^$top_info" <<< "$user_info" | cut -f 2- -d ' ')
			if [[ "$user_top" != "" ]]; then
				enable_markdown=true
				parse_mode=html
				user_fname=$(grep '^fname' <<< "$user_info" | cut -f 2- -d ' ' | sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g')
				user_lname=$(grep '^lname' <<< "$user_info" | cut -f 2- -d ' ' | sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g')
				user_entry="$user_top<b> ☆ $user_fname $user_lname</b>"
				p_user_top=$(printf '%s\n' "${p_user_entry[@]}" | sort -nr | head -n 10)
				text_id=$(printf '%s\n' "$user_entry" "$p_user_top")
				tg_method send_message
			fi
		;;
		"!neofetch")
			text_id=$(neofetch --stdout)
			markdown=("<code>" "</code>")
			parse_mode=html
			get_reply_id self
			tg_method send_message
		;;
		"!owo")
			if [[ "${user_text[1]}" ]]; then
				reply=${user_text[1]}
				numberspace=$(tr -dc ' ' <<< "$reply" | wc -c)

				[[ "$numberspace" -eq "0" ]] && reply="$reply " && numberspace=1

				owoarray=("owo" "ewe" "uwu" ":3" "x3")

				for x in $(seq $(((numberspace / 16)+1))); do
					reply=$(sed "s/\s/ ${owoarray[$((RANDOM % ${#owoarray[@]}))]} /$(((RANDOM % numberspace)+1))" <<< "$reply")
				done

				text_id=$(sed -e 's/[lr]/w/g' -e 's/[LR]/W/g' <<< "$reply")
				get_reply_id reply
			else
				command_help
			fi
			if [[ "${user_id[1]}" == "$(jshon -Q -e result -e id -u < botinfo)" ]]; then
				edit_id=${message_id[1]}
				edit_text=$text_id
				tg_method edit_text
			else
				tg_method send_message
			fi
		;;
		"!ping")
			markdown=("<code>" "</code>")
			parse_mode=html
			text_id=$(printf '%s\n' \
				"pong" \
				"api: /getMe method time: $({ time tg_method get_me; } 2>&1 1>/dev/null \
					| tr -s " " \
					| cut -f 2 -d " ")" \
				"response time: $(bc -l <<< "$(date +%s)-$(jshon -Q -e date -u <<< "$message")") s" \
				"script time: $(bc <<< "$(bc <<< "$(date +%s%N) / 1000000") - $START_TIME") ms")
			get_reply_id self
			tg_method send_message
		;;
		"!reverse")
			file_name="reverse"
			if [[ "${video_id[1]}" ]]; then
				media=${video_id[1]}
				filters="-vf reverse -af areverse"
				method=send_video
				video_id="@$file_name.mp4"
				ext=mp4
			elif [[ "${animation_id[1]}" ]]; then
				media=${animation_id[1]}
				filters="-vf reverse"
				method=send_animation
				animation_id="@$file_name.mp4"
				ext=mp4
			elif [[ "${audio_id[1]}" ]]; then
				media=${audio_id[1]}
				filters="-af areverse"
				method=send_audio
				audio_id="@$file_name.mp3"
				ext=mp3
			elif [[ "${voice_id[1]}" ]]; then
				media=${voice_id[1]}
				filters="-af areverse"
				method=send_voice
				voice_id="@$file_name.ogg"
				ext=ogg
			else
				return
			fi
			get_reply_id self
			loading 1

			twd
			tg_method get_file "$media"
			file_path="$(jshon -Q -e result -e file_path -u <<< "$curl_result")"
			remote_file_path="${TELEAPI_BASE_URL}/file/bot$TOKEN/$file_path"
			ffmpeg -v error -i "$remote_file_path" $filters "$file_name.$ext"
			loading 2
			tg_method $method upload
			loading 3
		;;
		"!sed")
			[[ "${caption[1]}" != "" ]] && user_text[1]=${caption[1]}
			if [[ "${user_text[1]}" != "" ]] && [[ "${arg[0]}" ]]; then
				pattern=$(sed "s/^.sed //" <<< "$user_text")
				text_id=$(sed --sandbox "$pattern" <<< "${user_text[1]}" 2>&1)
				get_reply_id reply
			else
				command_help
			fi
			tg_method send_message
		;;
		"!stats")
			source tools/stats.sh
			get_reply_id self
			if [[ "$photo_id" == "" ]]; then
				text_id="stats not found"
				tg_method send_message
			else
				tg_method send_photo upload
				rm -f "$data_id-data" "$data_id-out.png"
			fi
			cd "$basedir"
		;;
		"!tag")
			if [[ "${user_text[1]}" == "" ]]; then
				text_id=$(sed "s/$command ${arg[0]} //" <<< "$user_text")
			else
				text_id=${user_text[1]}
			fi
			tag_name=${arg[0]}
			case "$tag_name" in
				[0-9]*)
					tag_id=$tag_name
				;;
				*)
					tag_id=$(grep '^id:' $(grep -ri -- "$(sed 's/@//' <<< "$tag_name")" "$basedir/db/users/" | cut -d : -f 1) | head -n 1 | sed 's/.*id: //')
				;;
			esac
			if [[ "$text_id" == "" ]]; then
				command_help
			elif [[ "$tag_id" == "" ]]; then
				text_id="$tag_name not found"
			elif [[ "$tag_id" ]] && [[ "$text_id" ]]; then
				markdown=("<a href=\"tg://user?id=$tag_id\">" "</a>")
				parse_mode=html
			fi
			tg_method send_message
		;;
		"!top")
			get_reply_id self
			top_info="gs"
			list_top=$(grep -r "^$top_info" "$basedir/db/users/" | cut -d : -f 1)
			if [[ "$list_top" != "" ]]; then
				for x in $(seq $(wc -l <<< "$list_top")); do
					user_file=$(sed -n ${x}p <<< "$list_top")
					user_info=$(grep "^fname\|^lname\|^$top_info" "$user_file")
					user_top=$(grep "^$top_info" <<< "$user_info" | cut -f 2- -d ' ')
					user_fname=$(grep '^fname' <<< "$user_info" | cut -f 2- -d ' ' | sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g')
					user_lname=$(grep '^lname' <<< "$user_info" | cut -f 2- -d ' ' | sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g')
					user_entry[$x]="$user_top<b> ☆ $user_fname $user_lname</b>"
				done
				enable_markdown=true
				parse_mode=html
				text_id=$(sort -nr <<< "$(printf '%s\n' "${user_entry[@]}")" | head -n 10)
				tg_method send_message
			fi
		;;
		"!wget")
			if [[ "${user_text[1]}" != "" ]]; then
				wget_link=${user_text[1]}
			else
				wget_link=${arg[0]}
			fi
			wget_check=$(wget --spider -S -- "$wget_link" 2>&1 \
				| grep "^  HTTP" | tail -n 1 | cut -f 4 -d " ")
			if [[ "$wget_check" == "200" ]]; then
				twd
				loading 1
				wget_file=$(wget -E -nv -- "$(sed 's@+@ @g;s@%@\\x@g' <<< "$wget_link" \
					| xargs -0 printf "%b")" 2>&1 \
						| cut -f 6- -d ' ' \
						| tr ' ' '\n' | head -n -1 | tr '\n' ' ')
				if [[ "$wget_file" ]]; then
					document_id="@$wget_file"
					loading 2
					tg_method send_document upload
					loading 3
				else
					loading value "file not found"
				fi
			fi
		;;
		"!ytdl")
			[[ -e "$basedir/powersave" ]] && return
			get_reply_id self
			if [[ "${user_text[1]}" ]]; then
				ytdl_link=${user_text[1]}
			elif [[ "${arg[0]}" ]]; then
				ytdl_link=${arg[0]}
			else
				text_id="no link provided"
				tg_method send_message
				return
			fi
			ytdl_link=$(sed -n "s|.*\(http[^\s]*\)|\1|p" <<< "$ytdl_link")
			loading 1
			twd
			source "$basedir/venv/bin/activate"
			if [[ "$(sed "s/.* //" <<< "${arg[*]}")" == "audio" ]]; then
				ext=mp3
				ytdl_json=$(yt-dlp --print-json --extract-audio \
					--audio-format mp3 -o ytdl.$ext "$ytdl_link")
			else
				ext=mp4
				ytdl_json=$(yt-dlp --print-json \
					--merge-output-format $ext -o ytdl.$ext "$ytdl_link")
			fi
			deactivate
			if [[ "$ytdl_json" != "" ]]; then
				caption=$(jshon -Q -e title -u <<< "$ytdl_json")
				if [[ "$(du -m ytdl.$ext | cut -f 1)" -ge 2000 ]]; then
					loading value "upload limit exceeded"
				else
					case "$ext" in
						mp4)
							video_id="@ytdl.$ext"
							loading 2
							tg_method send_video upload
						;;
						mp3)
							mv "ytdl.$ext" "$caption.$ext"
							audio_id="@$caption.$ext"
							unset caption
							loading 2
							tg_method send_audio upload
						;;
					esac
					loading 3
				fi
			else
				loading value "invalid link"
			fi
		;;

		# bot admin

		"!bin")
			markdown=("<code>" "</code>")
			parse_mode=html
			if [[ $(is_status admins) ]]; then
				bin=$(sed "s/^$command //" <<< "$user_text")
				case "$user_text" in
					"!bin "*)
						export user_text
						export reply_text=${user_text[1]}
						text_id=$(mksh -c "$bin" 2>&1)
					;;
				esac
				if [[ "$text_id" = "" ]]; then
					text_id="[no output]"
				fi
			else
				text_id="Access denied"
			fi
			get_reply_id reply
			tg_method send_message
		;;
		"!broadcast")
			if [[ $(is_status admins) ]]; then
				listchats=$(printf '%s\n' "$(dir -1 "$basedir/db/chats/")" \
					| sort -u | grep -vw -- "$chat_id")
				numchats=$(wc -l <<< "$listchats")
				if [[ "${arg[0]}" ]]; then
					text_id=$(sed "s/^$command //" <<< "$user_text")
					for x in $(seq "$numchats"); do
						chat_id=$(sed -n "${x}p" <<< "$listchats")
						type=$(set +f ; sed -n 's/^type: //p' \
							"$basedir"/db/*/"$chat_id" ; set -f)
						if [[ "$type" != "channel" ]]; then
							tg_method send_message
						fi
					done
				elif [[ "${message_id[1]}" != "" ]]; then
					from_chat_id=$chat_id
					copy_id=${message_id[1]}
					for x in $(seq "$numchats"); do
						chat_id=$(sed -n ${x}p <<< "$listchats")
						type=$(set +f ; sed -n 's/^type: //p' \
						"$basedir"/db/*/"$chat_id" ; set -f)
						if [[ "$type" != "channel" ]]; then
							tg_method copy_message
						fi
					done
				else
					text_id="Write something after broadcast command or reply to forward"
					send_message
				fi
			else
				markdown=("<code>" "</code>")
				parse_mode=html
				text_id="Access denied"
				send_message
			fi
		;;
		"!db")
			if [[ $(is_status admins) ]]; then
				case "${arg[0]}" in
					"chats")
						for x in $(seq $(dir -1 "$basedir/db/chats/" | wc -l)); do
							info_chat=$(dir -1 "$basedir/db/chats/" | sed -n ${x}p)
							count[$x]=$(curl -s "$TELEAPI/getChatMembersCount" --form-string "chat_id=$info_chat" | jshon -Q -e result -u)
							info[$x]="${count[$x]} members, $(cat -- "$basedir/db/chats/$info_chat" \
							| grep "^title\|^type" | sed -e 's/^title: //' -e 's/^type:/,/' | tr -d '\n')"
							if [[ "${count[$x]}" == "" ]]; then
								unset info[$x]
								rm -f -- "$basedir/db/chats/$info_chat"
							fi
						done
						text_id=$(printf '%s\n' "${info[@]}" | sort -nr)
						get_reply_id any
						tg_method send_message
					;;
					"get")
						if [[ "${user_id[1]}" ]]; then
							text_id=$(cat "$basedir/db/users/${user_id[1]}")
							get_reply_id any
							tg_method send_message
						fi
					;;
				esac
			fi
		;;
		"!del"|"!delete")
			if [[ $(is_status admins) ]] \
			&& [[ "${user_id[1]}" == "$(jshon -Q -e result -e id -u < botinfo)" ]]; then
				to_delete_id=${message_id[1]}
				tg_method delete_message
			fi
		;;
		"!exit")
			get_reply_id self
			if [[ $(is_status admins) ]]; then
				text_id="goodbye"
				tg_method send_message
				tg_method leave_chat
			else
				markdown=("<code>" "</code>")
				parse_mode=html
				text_id="Access denied"
				tg_method send_message
			fi
		;;
		"!powersave")
			if [[ $(is_status admins) ]]; then
				if [[ ! -e "$basedir/powersave" ]]; then
					touch "$basedir/powersave"
					text_id="powersave set"
				else
					rm -f "$basedir/powersave"
					text_id="powersave unset"
				fi
				get_reply_id self
				tg_method send_message
			fi
		;;
		"!set")
			if [[ $(is_status admins) ]]; then
				set_username=$(sed 's/^@//' <<< "${arg[1]}")
				set_file=$(grep -ir -- "$set_username" "$basedir/db/users/" | head -n 1 | cut -d : -f 1)
				set_id=$(grep '^id' "$set_file" | sed 's/^id: //')
				if [[ "$set_id" != "" ]]; then
					case "${arg[0]}" in
						admin)
							set_check=$(grep -w -- "^$set_id" admins)
							if [[ "$set_check" = "" ]]; then
								printf '%s\n' "$set_id:$set_username" >> admins
								text_id="done"
							fi
						;;
						normal|demote)
							set_check=$(grep -w -- "^$set_id" admins)
							if [[ "$set_check" != "" ]]; then
								sed -i "/^$set_id/d" admins
								text_id="done"
							fi
						;;
						ban|deny)
							set_check=$(grep -w -- "^$set_id" banned)
							if [[ "$set_check" = "" ]]; then
								printf '%s\n' "$set_id:$set_username" >> banned
								text_id="done"
							fi
						;;
						unban|allow)
							set_check=$(grep -w -- "^$set_id" banned)
							if [[ "$set_check" != "" ]]; then
								sed -i "/^$set_id/d" banned
								text_id="done"
							fi
						;;
					esac
				else
					text_id="$set_username not found"
				fi
				[[ "$text_id" != "" ]] && tg_method send_message
			fi
		;;

		# chat admin

		"!autodel")
			if [[ $(is_chat_admin) ]]; then
				if [[ "$(grep -o "^[0-9]*" <<< "${arg[0]}")" ]]; then
					if [[ "${arg[0]/s/}" -lt "172800" ]] \
					&& [[ "${arg[0]/s/}" -ge "5" ]]; then
						text_id="autodel set to ${arg[0]}"
						printf '%s\n' "autodel: ${arg[0]}" >> "$basedir/db/chats/$chat_id"
					else
						text_id="invalid time specified"
					fi
				else
					if [[ "$(grep "^autodel" "$basedir/db/chats/$chat_id")" ]]; then
						sed -i "/^autodel: /d" "$basedir/db/chats/$chat_id"
						text_id="autodel disabled"
						tg_method send_message
					fi
				fi
			fi
		;;
		"!autounpin")
			if [[ $(is_chat_admin) ]]; then
				get_reply_id self
				if [[ "$(grep "^chan_unpin" "$basedir/db/chats/$chat_id")" ]]; then
					sed -i '/^chan_unpin/d' "$basedir/db/chats/$chat_id"
					text_id="autounpin disabled"
				else
					printf '%s\n' "chan_unpin" >> "$basedir/db/chats/$chat_id"
					text_id="autounpin enabled"
				fi
				tg_method send_message
			fi
		;;
		"!flush")
			if [[ $(is_chat_admin) ]] && [[ "${message_id[1]}" ]]; then
				text_id="flushing..."
				tg_method send_message
				flush_id=$(jshon -Q -e result -e message_id -u <<< "$curl_result")
				for x in $(seq "$message_id" -1 "${message_id[1]}"); do
					to_delete_id=$x
					tg_method delete_message &
					sleep 0.1
				done
				to_delete_id=$flush_id
				tg_method delete_message
			fi
		;;
		"!nopremium")
			if [[ $(is_chat_admin) ]]; then
				if [[ "$(grep "^nopremium" "$basedir/db/chats/$chat_id")" ]]; then
					sed -i "/^nopremium/d" "$basedir/db/chats/$chat_id"
					text_id="nopremium disabled"
				else
					printf '%s\n' "nopremium" >> "$basedir/db/chats/$chat_id"
					text_id="nopremium enabled"
				fi
				tg_method send_message
			fi
		;;
		"!warn"|"!ban"|"!kick")
			if [[ $(is_chat_admin) ]]; then
				if [[ "${user_id[1]}" ]] && [[ "${user_id[1]}" != "$user_id" ]]; then
					restrict_id=${user_id[1]}
				else
					case "${arg[0]}" in
						[0-9]*)
							restrict_id=${arg[0]}
						;;
						*)
							restrict_id=$(grep '^id:' $(grep -ri -- "$(sed 's/@//' <<< "${arg[0]}")" "$basedir/db/users/" | cut -d : -f 1) | head -n 1 | sed 's/.*id: //')
							if [[ "$restrict_id" == "$user_id" ]]; then
								unset restrict_id
							fi
						;;
					esac
				fi
				if [[ "$restrict_id" ]]; then
					if [[ "${user_fname[1]}" == "" ]]; then
						restrict_fname=$(grep -w -- "^fname" "$basedir/db/users/$restrict_id" | sed 's/.*fname: //')
					else
						restrict_fname=${user_fname[1]}
					fi
					get_member_id=$restrict_id
					tg_method get_chat_member
					if [[ "$(jshon -Q -e ok -u <<< "$curl_result")" == "true" ]]; then
						if [[ "$(grep -w -- "^$restrict_id" admins)" ]]; then
							get_reply_id self
							sticker_id="CAACAgQAAxkBAAEMIRxhJPew20PQ6R9SpGdAqbx4JisVagACBwgAAivRkQnNn3jPdYYwhCAE"
							tg_method send_sticker
						else
							case "$command" in
								"!warn")
									warns=$(grep "^warns-$chat_id:" "$basedir/db/users/$restrict_id" | sed 's/.*: //')
									if [[ "$warns" == "" ]]; then
										warns=1
										printf '%s\n' "warns-$chat_id: $warns" >> "$basedir/db/users/$restrict_id"
									elif [[ "$warns" -eq "1" ]]; then
										warns=$(($warns+1))
										sed -i "s/^warns-$chat_id: .*/warns-$chat_id: $warns/" "$basedir/db/users/$restrict_id"
									elif [[ "$warns" -eq "2" ]]; then
										warns=$(($warns+1))
										sed -i "s/^warns-$chat_id: .*//" "$basedir/db/users/$restrict_id"
										sed -i '/^$/d' "$basedir/db/users/$restrict_id"
										can_send_messages="false"
										can_send_media_messages="false"
										can_send_other_messages="false"
										can_send_polls="false"
										can_add_web_page_previews="false"
										tg_method restrict_member
									fi
									if [[ "$(jshon -Q -e ok -u <<< "$curl_result")" != "false" ]]; then
										get_reply_id reply
										text_id="$restrict_fname warned ($warns out of 3)"
									else
										get_reply_id self
										text_id="error"
									fi
								;;
								"!kick"|"!ban")
									get_reply_id self
									ban_id=$restrict_id
									get_chat_id=$chat_id
									tg_method get_chat
									linked_chat_id=$(jshon -Q -e result -e linked_chat_id -u <<< "$curl_result")
									if [[ "$linked_chat_id" ]]; then
										chat_id[1]=$chat_id
										chat_id[0]=$linked_chat_id
										tg_method get_chat_member
										if [[ ! "$(jshon -Q -e result -e status -u <<< "$curl_result" | grep -w "administrator")" ]]; then
											chat_id[0]=${chat_id[1]}
											unset chat_id[1]
										fi
									fi
									for x in ${chat_id[@]}; do
										chat_id=$x
										tg_method ban_member
										case "$command" in
											"!kick")
												if [[ "$(jshon -Q -e ok -u <<< "$curl_result")" != "false" ]]; then
													unban_id=$ban_id
													tg_method unban_member
													if [[ "$(jshon -Q -e ok -u <<< "$curl_result")" != "false" ]]; then
														text_id="$restrict_fname kicked"
													fi
												fi
											;;
											"!ban")
												if [[ "$(jshon -Q -e ok <<< "$curl_result")" != "false" ]]; then
													text_id="$restrict_fname banned"
												fi
											;;
										esac
									done
								;;
							esac
							tg_method send_message
						fi
					fi
				fi
			fi
		;;
	esac
	if [[ -e "$basedir/custom_commands/user_generated/$chat_id-$user_text" ]]; then
		text_id=$(cat -- "$basedir/custom_commands/user_generated/$chat_id-$user_text")
		get_reply_id self
		tg_method send_message
	fi
	if [[ "$twd_dir" ]]; then
		twd exit
	fi
}
case_normal() {
	if [[ "$(grep -r -- "$bot_chat_user_id" "$bot_chat_dir")" ]]; then
		bot_chat=$(grep -r -- "$bot_chat_user_id" "$bot_chat_dir")
		bot_chat_id=$(cut -f 1 -d : <<< "$bot_chat" | cut -f 3 -d /)
		bc_users=$(sed 's/.*:\s//' <<< "$bot_chat" | tr ' ' '\n')
		if [[ "$bc_users" ]]; then
			to_delete_id=$message_id
			tg_method delete_message
			bc_users_num=$(wc -l <<< "$bc_users")
			case "$file_type" in
				text)
					text_id=$user_text
					method=send_message
				;;
				photo)
					method=send_photo
				;;
				animation)
					method=send_animation
				;;
				sticker)
					method=send_sticker
				;;
				video)
					method=send_video
				;;
				voice)
					method=send_voice
				;;
				audio)
					method=send_audio
				;;
			esac
			for c in $(seq "$bc_users_num"); do
				chat_id=$(sed -n ${c}p <<< "$bc_users")
				bot_chat_send_message "$chat_id" &
			done
			wait
		fi
	fi
}
if [[ "$command" ]]; then
	case_command
else
	case_normal
fi

case "$file_type" in
	"new_chat_members")
		new_member_id=$(jshon -Q -e 0 -e id -u <<< "$new_members")
		if [[ "$new_member_id" == "$(jshon -Q -e result -e id -u < botinfo)" ]]; then
			voice_id="https://archneek.me/public/audio/oh_my.ogg"
		elif [[ "$(grep "160551211\|917684979" <<< "$new_member_id")" ]]; then
			voice_id="https://archneek.me/public/audio/the_holy.ogg"
		else
			voice_id="https://archneek.me/public/audio/fanfare.ogg"
		fi
		get_reply_id self
		tg_method send_voice
	;;
esac

if [[ "$(grep "^chan_unpin" "$basedir/db/chats/$chat_id")" ]]; then
	if [[ "$(jshon -Q -e sender_chat -e type -u <<< "$message")" == "channel" ]]; then
		curl -s "$TELEAPI/unpinChatMessage" \
		--form-string "message_id=$message_id" \
		--form-string "chat_id=$chat_id" > /dev/null
	fi
fi

if [[ "$(grep "^autodel" "$basedir/db/chats/$chat_id")" ]]; then
	if [[ "$curl_result" == "" ]]; then
		(sleep $(sed -n "s/^autodel: //p" "$basedir/db/chats/$chat_id")  \
		&& curl -s "$TELEAPI/deleteMessage" \
			--form-string "message_id=$message_id" \
			--form-string "chat_id=$chat_id" > /dev/null) &
	else
		(sleep $(sed -n "s/^autodel: //p" "$basedir/db/chats/$chat_id")  \
		&& curl -s "$TELEAPI/deleteMessage" \
			--form-string "message_id=$message_id" \
			--form-string "chat_id=$chat_id" > /dev/null
			curl -s "$TELEAPI/deleteMessage" \
			--form-string "message_id=$(jshon -Q -e result -e message_id <<< "$curl_result")" \
			--form-string "chat_id=$chat_id" > /dev/null) &
	fi
fi


if [[ "$(grep "^nopremium" "$basedir/db/chats/$chat_id")" ]] && [[ $(is_chat_admin bot_only) ]] \
	&& [[ "$is_premium" ]]; then
	to_delete_id=$message_id
	tg_method delete_message
	
	if [[ ! -e "$basedir/db/p/$chat_id-$user_id" ]]; then
		[[ ! -d "$basedir/db/p" ]] && mkdir "$basedir/db/p"
		cd "$basedir/db/p"
		touch -- "$chat_id-$user_id"
		cd -
	fi
fi
