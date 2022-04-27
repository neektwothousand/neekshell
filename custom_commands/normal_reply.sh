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
	tg_method get_file "${video_id[1]}"
	file_path=$(jshon -Q -e result -e file_path -u <<< "$curl_result")
	ext=$(sed 's/.*\.//' <<< "$file_path")
	if [[ "$ext" == "gif" ]]; then
		ffmpeg -i "$file_path" "video.mp4"
	else
		cp "$file_path" "video.$ext"
	fi
	loading 1
	video_info=$(ffprobe -v error \
		-show_entries stream=sample_rate,bit_rate,duration,width,height,r_frame_rate \
		-of default=noprint_wrappers=1 "$file_path")
	res[0]=$(sed -n 's/^width=//p' <<< "$video_info")
	res[1]=$(sed -n 's/^height=//p' <<< "$video_info")
	res[0]=$(bc <<< "${res[0]}/1.5")
	res[1]=$(bc <<< "${res[1]}/1.5")
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
	ffmpeg -i "video.$ext" \
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
		mkdir "$twd_dir" ; cd "$twd_dir"
	else
		cd "$tmpdir"
		rm -rf "twd_$twd_id/"
		cd "$basedir"
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
										sed -i "s/\(users: \)/\1$user_id /" $bot_chat_dir"$join_chat"
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
				case "${file_type[1]}" in
					video|animation)
						input_codecs=$(ffprobe -v error -show_streams "$file_path" | grep "^codec_name")
						case "${file_type[1]}" in
						video) media_id=${video_id[1]} ;;
						animation) media_id=${animation_id[1]} ;;
						esac
						file_path=$(curl -s "${TELEAPI}/getFile" --form-string "file_id=$media_id" | jshon -Q -e result -e file_path -u)
						case "${arg[0]}" in
							animation)
								loading 1
								out_file="convert.mp4"
								if [[ "$(grep "^codec_name=h264$" <<< "$input_codecs")" ]]; then
									out_vcodec=copy
								else
									out_vcodec=h264
								fi
								err_out=$(ffmpeg -v error -i "$file_path" -vcodec $out_vcodec -an "$out_file")
								loading 2
								animation_id="@$out_file"
								tg_method send_animation upload
							;;
						esac
					;;
					photo|sticker)
						case "${file_type[1]}" in
						photo) media_id=${photo_id[1]} ;;
						sticker) media_id=${sticker_id[1]} ;;
						esac
						file_path=$(curl -s "${TELEAPI}/getFile" --form-string "file_id=$media_id" | jshon -Q -e result -e file_path -u)
						case "${arg[0]}" in
							webp)
								loading 1
								out_file="convert.webp"
								err_out=$(convert "$file_path" "$out_file")
								loading 2
								sticker_id="@$out_file"
								tg_method send_sticker upload
							;;
							jpg)
								loading 1
								out_file="convert.jpg"
								err_out=$(convert "$file_path" "$out_file")
								loading 2
								photo_id="@$out_file"
								tg_method send_photo upload
							;;
							png)
								loading 1
								out_file="convert.png"
								err_out=$(convert "$file_path" "$out_file")
								loading 2
								document_id="@$out_file"
								tg_method send_document upload
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
				[[ ! -d custom_commands/user_generated/ ]] \
					&& mkdir custom_commands/user_generated/
				printf '%s\n' "$user_text" \
					| sed "s/$command ${arg[0]} //" \
					> "custom_commands/user_generated/$chat_id-$user_command"
				text_id="$user_command set"
			else
				command_help
			fi
			tg_method send_message
		;;
		"!deemix")
			[[ -e "$basedir/powersave" ]] && return
			if [[ "${user_text[1]}" != "" ]] || [[ "${arg[0]}" != "" ]]; then
				if [[ "${user_text[1]}" != "" ]]; then
					deemix_link=$(grep -o 'https://www.deezer.*\|https://deezer.*' <<< "${user_text[1]}" | cut -f 1 -d ' ')
				elif [[ "${arg[0]}" != "" ]]; then
					deemix_link=${arg[0]}
				fi
				if [[ "$(grep 'track\|album\|deezer.page.link' <<< "$deemix_link")" != "" ]]; then
					twd
					loading 1
					export LC_ALL=C.UTF-8
					export LANG=C.UTF-8
					~/.local/bin/deemix -b flac -p ./ "$deemix_link" 2>&1 > /dev/null
					downloaded=$(dir -N1)
					if [[ "$(dir -N1 "$downloaded" | wc -l)" -gt "1" ]]; then
						up_type=archive
						set +f
						zip -r "$downloaded.zip" "$downloaded" > /dev/null
						set -f
						document_id="@$downloaded.zip"
					else
						up_type=audio
						audio_id="@$downloaded"
					fi
					get_reply_id any
					case "$up_type" in
						archive)
							if [[ "$(du -m -- "$downloaded.zip" | cut -f 1)" -ge 2000 ]]; then
								loading 3
								text_id="file size exceeded"
								tg_method send_message
							else
								loading 2
								tg_method send_document upload
								loading 3
							fi
						;;
						audio)
							if [[ "$(du -m -- "$downloaded" | cut -f 1)" -ge 2000 ]]; then
								loading 3
								text_id="file size exceeded"
								tg_method send_message
							else
								loading 2
								tg_method send_audio upload
								loading 3
							fi
						;;
					esac
				fi
			else
				command_help
				tg_method send_message
			fi
		;;
		"!d"|"!dice")
			get_reply_id self
			case "${arg[0]}" in
				[0-9]*|[0-9]*"*"[0-9]*)
					if [[ "$(grep "*" <<< "$user_text")" != "" ]]; then
						normaldice=$(sed "s/!d//" <<< "$user_text" | cut -d "*" -f 1)
						mul=$(sed "s/!d//" <<< "$user_text" | cut -d "*" -f 2)
					else
						normaldice=$(sed "s/!d//" <<< "$user_text")
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
		"!parrot")
			get_member_id=$(jshon -Q -e result -e id -u < botinfo)
			tg_method get_chat_member
			if [[ "$(jshon -Q -e result -e status -u <<< "$curl_result" | grep -w "administrator")" != "" ]]; then
				ban_id=$user_id
				tg_method ban_member
				if [[ "$(jshon -Q -e ok -u <<< "$curl_result")" != "false" ]]; then
					unban_id=$user_id
					tg_method unban_member
				fi
			fi
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
					file_path=$(curl -s "${TELEAPI}/getFile" --form-string "file_id=$media_id" | jshon -Q -e result -e file_path -u)
					text_id=$(ffprobe "$file_path" 2>&1 | grep -v '^  lib' | sed '1,4d' | sed 's/^  //')
					markdown=("<code>" "</code>")
					parse_mode=html
					tg_method send_message
				fi
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
		"!ugoira-dl")
			[[ -e "$basedir/powersave" ]] && return
			if [[ "${arg[0]}" ]]; then
				get_reply_id self
				loading 1
				gallery_json=$(gallery-dl -sj "${arg[0]}" 2>/dev/null)
				if [[ "$gallery_json" ]]; then
					gallery_type=$(jshon -Q -e 0 -e 1 -e type -u <<< "$gallery_json")
					if [[ "$gallery_type" == "ugoira" ]]; then
						twd
						gallery-dl -q --ugoira-conv-lossless -d . -D . -f out.webm "${arg[0]}"
						ffmpeg -v error -i out.webm -vcodec h264 -crf 14 -an out.mp4
						animation_id="@out.mp4"
						loading 2
						tg_method send_animation upload
						loading 3
					else
						loading value "ugoira not found"
					fi
				else
					loading value "invalid link"
				fi
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
		"!g"[tbrl]"t")
			[[ -e "$basedir/powersave" ]] && return
			if [[ "${message_id[1]}" != "" ]]; then
				twd
				get_reply_id reply
				case "${file_type[1]}" in
					animation|photo|video)
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
						esac
						file_path=$(curl -s "${TELEAPI}/getFile" --form-string "file_id=$media_id" | jshon -Q -e result -e file_path -u)
						ext=$(sed 's/.*\.//' <<< "$file_path")
						toptext=$(sed -e "s/$(head -n 1 <<< "$user_text" | cut -f 1 -d ' ') //" -e "s/,/\\\,/g" <<< "$user_text")
						loading 1
						case "$command" in
							"!gtt") mode=top ;;
							"!gbt") mode=bottom ;;
							"!grt") mode=right ;;
							"!glt") mode=left ;;
						esac
						source "$basedir/tools/toptext.sh" \
							"$toptext" "$mode" "$file_path"

						loading 2
						case "${file_type[1]}" in
							animation)
								animation_id="@toptext.$ext"
								tg_method send_animation upload
							;;
							video)
								video_id="@toptext.$ext"
								tg_method send_video upload
							;;
							photo)
								photo_id="@toptext.$ext"
								tg_method send_photo upload
							;;
						esac
						loading 3
					;;
				esac
			fi
		;;
		"!hide"|"!unhide")
			if [[ "${message_id[1]}" ]]; then
				if [[ "${file_type[1]}" == "photo" ]]; then
					twd
					get_reply_id reply
					file_path=$(curl -s "${TELEAPI}/getFile" --form-string "file_id=${photo_id[1]}" | jshon -Q -e result -e file_path -u)
					ext=$(sed 's/.*\.//' <<< "$file_path")
					cp "$file_path" "pic.$ext"
					if [[ "${arg[1]}" == "" ]]; then
						seed="defaultpasswordthatisreallyhardtoguessiguess"
					else
						seed="${arg[1]}"
					fi
					case "$command" in
						"!hide")
							result=$(imageobfuscator \
								-i "pic.$ext" \
								-e -p "${arg[0]}" -s "$seed")
							if [[ "$result" == "Saved." ]]; then
								document_id="@pic_encoded.png"
								tg_method send_document upload
								rm -f "pic_encoded.png"
							fi
						;;
						"!unhide")
							text_id=$(imageobfuscator \
								-i "pic.$ext" -d -s "$seed" \
								| cut -f 2 -d ' ')
							if [[ "$text_id" == "" ]]; then
								text_id="Wrong password, image has no hidden data."
							fi
							tg_method send_message
						;;
					esac
				fi
			else
				command_help
				tg_method send_message
			fi
		;;
		"!insert"|"!extract")
			if [[ "$chat_type" == "private" ]]; then
				file_chat=$file_user
			fi
			case "$command" in
				"!insert")
					if [[ ! "$(grep "^pool" "$file_chat")" ]]; then
						printf '%s\n' "pool: ${arg[*]}" >> "$file_chat"
					else
						sed -i "s/\(^pool: \).*/\1${arg[*]} /" "$file_chat"
					fi
					text_id=$(grep "^pool:" "$file_chat")
					tg_method send_message
				;;
				"!extract")
					case "${arg[0]}" in
						[1-9]*)
							pool=($(sed -n "s/^pool: //p" "$file_chat"))
							if [[ "${arg[0]}" -gt "${#pool[@]}" ]]; then
								arg[0]=${#pool[@]}
							fi
							for x in $(seq 0 $((${arg[0]}-1))); do
								pool=(${pool[@]})
								pool_rand=$((RANDOM % ${#pool[@]}))
								text_id="${pool[$pool_rand]} $text_id"
								unset pool[$pool_rand]
							done
							tg_method send_message
						;;
					esac
				;;
			esac
		;;
		"!insta")
			[[ -e "$basedir/powersave" ]] && return
			if [[ "${arg[0]}" ]]; then
				if [[ "$(grep '^@' <<< "${arg[0]}")" != "" ]]; then
					arg[0]=${arg[0]/@/}
				fi
				if [[ "$(grep '[^_.a-zA-Z]' <<< "${arg[0]}")" != "" ]]; then
					return
				fi
				loading 1
				ig_user=$(sed -n 1p ig_key)
				ig_pass=$(sed -n 2p ig_key)
				twd
				ig_scraper=$(~/.local/bin/instagram-scraper -u $ig_user -p $ig_pass -m 50 "${arg[0]}")
				if [[ "$(grep "^ERROR" <<< "$ig_scraper")" != "" ]]; then
					loading 3
					return
				fi
				loading 2
				ls -t -1 "${arg[0]}" > ig_list
				printf '%s' "$user_id" > ig_userid
				if [[ "$(sed -n 2p ig_list)" != "" ]]; then
					button_text=(">")
					button_data=("insta + ${arg[0]} $chat_id")
					markup_id=$(json_array inline button)
				fi
				printf '%s' "1" > ig_page
				media_id="@$(sed -n 1p ig_list)"
				ext=$(grep -o "...$" <<< "$media_id")
				loading 3
				case "$ext" in
					jpg)
						photo_id=$media_id
						tg_method send_photo upload
						ig_id=$(jshon -Q -e result -e message_id -u <<< "$curl_result")
					;;
					mp4)
						video_id=$media_id
						tg_method send_video upload
						ig_id=$(jshon -Q -e result -e message_id -u <<< "$curl_result")
					;;
				esac
				printf '%s' "$ig_id" > ig_id
			else
				command_help
				tg_method send_message
			fi
		;;
		"!jpg")
			[[ -e "$basedir/powersave" ]] && return
			if [[ "${message_id[1]}" != "" ]]; then
				twd
				get_reply_id reply
				case "${file_type[1]}" in
					text)
						text_id=$("$basedir/tools/jpg" "${user_text[1]}")
						tg_method send_message
					;;
					photo)
						tg_method get_file "${photo_id[1]}"
						file_path=$(jshon -Q -e result -e file_path -u <<< "$curl_result")
						ext=$(sed 's/.*\.//' <<< "$file_path")
						if [[ "$(grep "png\|jpg\|jpeg" <<< "$ext")" != "" ]]; then
							case "$ext" in
								png)
									convert "$file_path" "pic.jpg"
									ext=jpg
								;;
								jpg|jpeg)
									cp "$file_path" "pic.jpg"
								;;
							esac
							res=($(ffprobe -v error -show_streams "pic.$ext" | sed -n -e 's/^width=\(.*\)/\1/p' -e 's/^height=\(.*\)/\1/p'))
							magick "pic.$ext" -resize $(printf '%.0f\n' "$(bc -l <<< "${res[0]}/2.5")")x$(printf '%.0f\n' "$(bc -l <<< "${res[1]}/2.5")") "pic.$ext"
							magick "pic.$ext" -quality 4 "pic.$ext"
							photo_id="@pic.$ext"
							tg_method send_photo upload
							rm "pic.$ext"
						fi
					;;
					sticker)
						if [[ "${sticker_is_animated[1]}" != "true" ]] && [[ "${sticker_is_video[1]}" != "true" ]]; then
							tg_method get_file "${sticker_id[1]}"
							file_path=$(jshon -Q -e result -e file_path -u <<< "$curl_result")
							cp "$file_path" "sticker.webp"
							res=($(ffprobe -v error -show_streams "sticker.webp" | sed -n -e 's/^width=\(.*\)/\1/p' -e 's/^height=\(.*\)/\1/p'))
							convert "sticker.webp" "sticker.jpg"
							magick "sticker.jpg" -resize $(bc <<< "${res[0]}/1.5")x$(bc <<< "${res[1]}/1.5") "sticker.jpg"
							magick "sticker.jpg" -quality 6 "sticker.jpg"
							magick "sticker.jpg" -resize 512x512 "sticker.jpg"
							convert "sticker.jpg" "sticker.webp"

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
						[[ "${file_type[1]}" == "voice" ]] && audio_id[1]=${voice_id[1]}
						tg_method get_file "${audio_id[1]}"
						file_path=$(jshon -Q -e result -e file_path -u <<< "$curl_result")
						ext=$(sed 's/.*\.//' <<< "$file_path")
						cp "$file_path" "audio.$ext"
						loading 1
						audio_info=$(ffprobe -v error \
							-show_entries stream=sample_rate,bit_rate \
							-of default=noprint_wrappers=1 "$file_path")
						br=$(sed -n 's/^bit_rate=//p' <<< "$audio_info" | head -n 1)
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
							-b:a $(bc <<< "$br/2") \
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
			printf '%s' "$input" | sed -e 's/{"/{\n"/g' -e 's/,"/,\n"/g' > decode-$update_id.json
			document_id=@decode-$update_id.json
			get_reply_id any
			tg_method send_document upload
			rm decode-$update_id.json
		;;
		"!me")
			if [[ "${arg[0]}" ]]; then
				text_id="> $user_fname $(sed "s/^$command //" <<< "$user_text")"
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
		"!nh")
			[[ -e "$basedir/powersave" ]] && return
			if [[ "${arg[0]}" ]]; then
				get_reply_id self
				nhentai_id=$(cut -d / -f 5 <<< "${arg[0]}")
				nhentai_check=$(wget -q -O- "https://nhentai.net/g/$nhentai_id/1/")
				loading 1
				if [[ "$nhentai_check" != "" ]]; then
					twd
					p_offset=1
					numpages=$(grep 'num-pages' <<< "$nhentai_check" \
						| sed -e 's/.*<span class="num-pages">//' -e 's/<.*//')
					for j in $(seq 0 $((numpages - 1))); do
						wget -q -O pic.jpg "$(wget -q -O- "https://nhentai.net/g/$nhentai_id/$p_offset/" \
							| grep 'img src' \
							| sed -e 's/.*<img src="//' -e 's/".*//')"
						graph_element[$j]=$(curl -s "https://telegra.ph/upload" -F "file=@pic.jpg" | jshon -Q -e 0 -e src -u)
						rm -f pic.jpg
						p_offset=$((p_offset + 1))
					done
					graph_title=$(wget -q -O- "https://nhentai.net/g/$nhentai_id" \
						| grep 'meta itemprop="name"' \
						| sed -e 's/.*<meta itemprop="name" content="//' -e 's/".*//')
					loading 2
					GRAPHTOKEN=$(jshon -Q -e result -e access_token -u < "$basedir/telegraph_data")
					GRAPHAPI="https://api.telegra.ph"
					for x in $(seq 0 $((${#graph_element[@]}-1))); do
						graph_content[$x]="{\"tag\":\"img\",\"attrs\":{\"src\":\"${graph_element[$x]}\"}},"
					done
					graph_content="[$(printf '%s' "${graph_content[*]}" | head -c -1)]"
					text_id=$(curl -s "$GRAPHAPI/createPage" -X POST -H 'Content-Type: application/json' \
						-d "{\"access_token\":\"$GRAPHTOKEN\",\"title\":\"$graph_title\",\"content\":${graph_content}}" \
						| jshon -Q -e result -e url -u)
					loading 3
					tg_method send_message
				else
					loading value "invalid id"
				fi
			fi
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
			text_id=$(printf '%s\n' \
				"pong" \
				"api: $(ping -c 1 api.telegram.org | grep time= | sed 's/.*time=//')" \
				"response time: $(bc -l <<< "$(date +%s)-$(jshon -Q -e date -u <<< "$message")") s" \
				"script time: $(bc <<< "$(bc <<< "$(date +%s%N) / 1000000") - $START_TIME") ms")
			get_reply_id self
			tg_method send_message
		;;
		"!reddit")
			get_reply_id self
			if [[ "${arg[0]}" ]]; then
				source tools/r_subreddit.sh "${arg[0]}" "${arg[1]}"
			else
				command_help
				tg_method send_message
			fi
		;;
		"!sauce")
			if [[ "${message_id[1]}" != "" ]]; then
				case "${file_type[1]}" in
					"photo"|"animation"|"video")
						request_id=$RANDOM
						case "${file_type[1]}" in
							photo) media_id=${photo_id[1]} ;;
							animation) media_id=${animation_id[1]} ;;
							video) media_id=${video_id[1]} ;;
						esac
						file_path=$(curl -s "${TELEAPI}/getFile" --form-string "file_id=$media_id" | jshon -Q -e result -e file_path -u)
						ext=$(sed 's/.*\.//' <<< "$file_path")
						if [[ "$(grep -i "mp4" <<< "$ext")" ]]; then
							public_path="/home/genteek/archneek/public/tmp/$request_id-sauce.jpg"
							request_url="https://archneek.zapto.org/public/tmp/$request_id-sauce.jpg"
							ffmpeg -ss 0.1 -i "$file_path" -vframes 1 -f image2 "$public_path"
						else
							public_path="/home/genteek/archneek/public/tmp/$request_id-sauce.$ext"
							request_url="https://archneek.zapto.org/public/tmp/$request_id-sauce.$ext"
							cp "$file_path" "$public_path"
						fi
						if [[ "${arg[0]}" == "google" ]]; then
							text_id=$(curl -s "https://www.google.com/searchbyimage?site=search&sa=X&image_url=$request_url" \
								| sed -n 's/^<A HREF="//p' | sed 's|">here</A>.||')
						else
							api_key=$(cat saucenao_key)
							params="output_type=2&numres=32&api_key=$api_key&url=$request_url"
							sauce=$(curl -s "https://saucenao.com/search.php?$params")
							numres=$(jshon -Q -e results -l <<< "$sauce")
							if [[ "$numres" ]]; then
								for x in $(seq 0 $((numres-1))); do
									ext_url[$x]=$(jshon -Q -e results -e $x -e data -e ext_urls -e 0 -u <<< "$sauce")
								done
								text_id=$(tr ' ' '\n' <<< "${ext_url[*]}")
							else
								text_id="no results"
							fi
						fi
						tg_method send_message
						rm -f "$public_path"
					;;
				esac
			fi
		;;
		"!sed")
			[[ "${caption[1]}" != "" ]] && user_text[1]=${caption[1]}
			if [[ "${user_text[1]}" != "" ]]; then
				text_id=$(sed --sandbox "${arg[*]}" <<< "${user_text[1]}" 2>&1)
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
		"!trad")
			if [[ "${user_text[1]}" ]]; then
				to_trad=${user_text[1]}
			elif [[ "${caption[1]}" ]]; then
				to_trad=${caption[1]}
			elif [[ "${arg[0]}" ]]; then
				to_trad=$(sed "s/$command //" <<< "$user_text")
			fi
			if [[ "$to_trad" ]]; then
				text_id=$(trans :en -j -b "$to_trad")
				get_reply_id self
				tg_method send_message
			fi
		;;
		"!tuxi")
			text_id=$(PATH=~/go/bin:~/.local/bin:$PATH tuxi -q -r -- "${arg[*]}")
			get_reply_id self
			tg_method send_message
		;;
		"!videosticker")
			[[ -e "$basedir/powersave" ]] && return
			if [[ "${message_id[1]}" ]]; then
				get_reply_id self
				if [[ "${file_type[1]}" == "animation" ]]; then
					tg_method get_file "${animation_id[1]}"
					file_path=$(jshon -Q -e result -e file_path -u <<< "$curl_result")
					ext=$(sed 's/.*\.//' <<< "$file_path")
					case "$ext" in
						mp4|gif|MP4|GIF)
							video_id[1]=${animation_id[1]}
							file_type[1]=video
						;;
					esac
				fi
				if [[ "${file_type[1]}" == "video" ]]; then
					[[ ! "$file_path" ]] \
						&& tg_method get_file "${video_id[1]}" \
						&& file_path=$(jshon -Q -e result -e file_path -u <<< "$curl_result")
					video_info=$(ffprobe -v error \
						-show_entries stream=duration,width,height,r_frame_rate \
						-of default=noprint_wrappers=1 "$file_path")
					duration=$(sed -n "s/^duration=//p" <<< "$video_info" | head -n 1 | sed "s/\..*//")
					if [[ "$duration" -le "3" ]]; then
						twd
						loading 1
						bot_username=$(jshon -Q -e result -e username -u < "$basedir/botinfo")
						frame_rate=$(sed -n "s/^r_frame_rate=//p" <<< "$video_info" | head -n 1 | cut -f 1 -d /)
						width=$(sed -n 's/^width=//p' <<< "$video_info")
						height=$(sed -n 's/^height=//p' <<< "$video_info")
						if [[ "$width" -ge "$height" ]]; then
							filter="-vf scale=512:-1"
						else
							filter="-vf scale=-1:512"
						fi
						if [[ "$frame_rate" -gt "30" ]]; then
							filter="$filter,fps=30"
						fi
						ffmpeg -v error -ss 0 -i "$file_path" \
							-vcodec vp9 -b:v 600k -an \
							-pix_fmt yuva420p $filter -t 3 sticker.webm
						sticker_id=@sticker.webm
						sticker_hash=$(md5sum sticker.webm | cut -f 1 -d ' ')
						loading 2
						curl -s "$TELEAPI/createNewStickerSet" \
							-F "user_id=$user_id" \
							-F "name=s${sticker_hash}_by_$bot_username" \
							-F "title=${sticker_hash}" \
							-F "webm_sticker=$sticker_id" \
							-F "emojis=⬛️" > /dev/null
						video_id=$sticker_id
						caption="https://t.me/addstickers/s${sticker_hash}_by_$bot_username"
						tg_method send_video upload
						loading 3
					else
						text_id="video duration must not exceed 3 seconds"
						tg_method send_message
					fi
				fi
			fi
		;;
		"!wget")
			if [[ "${user_text[1]}" != "" ]]; then
				wget_link=${user_text[1]}
			else
				wget_link=${arg[0]}
			fi
			if [[ "$wget_link" ]]; then
				twd
				loading 1
				wget_file=$(wget -E -nv "$wget_link" 2>&1 \
					| cut -f 6 -d ' ' \
					| sed -e s/^.// -e s/.$//)
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
			if [[ "${user_text[1]}" != "" ]]; then
				ytdl_link=${user_text[1]}
			else
				ytdl_link=${arg[0]}
			fi
			if [[ "$(curl -o /dev/null -ILsw '%{http_code}\n' "$ytdl_link")" == "200" ]]; then
				twd
				if [[ "$(grep vm.tiktok <<< "$ytdl_link")" ]]; then
					ua="--user-agent facebookexternalhit/1.1"
				fi
				loading 1
				ytdl_json=$(~/.local/bin/yt-dlp $ua --print-json --merge-output-format mp4 -o ytdl.mp4 "$ytdl_link")
				if [[ "$ytdl_json" != "" ]]; then
					caption=$(jshon -Q -e title -u <<< "$ytdl_json")
					if [[ "$(du -m ytdl.mp4 | cut -f 1)" -ge 2000 ]]; then
						loading value "error"
					else
						video_id="@ytdl.mp4"
						loading 2
						tg_method send_video upload
						loading 3
					fi
				else
					loading value "error"
				fi
			fi
		;;

		# bot admin

		"!bin"|"!archbin")
			markdown=("<code>" "</code>")
			parse_mode=html
			if [[ $(is_status admins) ]]; then
				bin=$(sed "s/^$command //" <<< "$user_text")
				case "$user_text" in
					"!bin "*)
						text_id=$(mksh -c "$bin" 2>&1)
					;;
					"!archbin "*)
						text_id=$(ssh neek@192.168.1.25 -p 24 "$bin")
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
				listchats=$(printf '%s\n' "$(grep -r users "$basedir/db/bot_chats/" | sed 's/.*: //' | tr ' ' '\n' | sed '/^$/d')" "$(dir -1 "$basedir/db/chats/")" | sort -u | grep -vw -- "$chat_id")
				numchats=$(wc -l <<< "$listchats")
				if [[ "${arg[0]}" ]]; then
					text_id=$(sed)
					for x in $(seq "$numchats"); do
						chat_id=$(sed -n ${x}p <<< "$listchats")
						tg_method send_message
					done
				elif [[ "${message_id[1]}" != "" ]]; then
					from_chat_id=$chat_id
					copy_id=${message_id[1]}
					for x in $(seq "$numchats"); do
						chat_id=$(sed -n ${x}p <<< "$listchats")
						tg_method copy_message
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
		"!loading")
			if [[ $(is_status admins) ]]; then
				cd "$tmpdir"
				case "${arg[0]}" in
					start)
						enable_markdown=true
						parse_mode=html
						text_id="<code>.. owo  owo ..</code>"
						tg_method send_message
						processing_id=$(jshon -Q -e result -e message_id -u <<< "$curl_result")
						printf '%s' "$processing_id" > loading-$user_id-$chat_id
						l_s=(" " "o" "w" "o" " " " " "o" "w" "o" " ")
						[[ "$processing_id" != "" ]] && load_status=true
						while [[ "$load_status" != "false" ]]; do
							for shift in $(seq $((${#l_s[*]}-1))); do
								shift=$((shift+1))
								y=$((shift-1))
								z=$y
								for x in $(seq 0 $((${#l_s[*]}-1))); do
									if [[ "$shift" = "" ]]; then
										x=$((x-z))
										load_text="${load_text}${l_s[$x]}"
									else
										s_e=$((${#l_s[*]}-y))
										s_a[$y]=${l_s[$s_e]}
										load_text="${load_text}${s_a[$y]}"
										y=$((y-1))
										[[ y -eq 0 ]] && unset shift
									fi
								done
								sleep 3
								loading value "<code>..${load_text}..</code>"
								load_status=$(jshon -Q -e ok -u <<< "$curl_result")
								unset load_text
							done
							sleep 3
							loading value "<code>.. owo  owo ..</code>"
							load_status=$(jshon -Q -e ok -u <<< "$curl_result")
						done
					;;
					stop)
						processing_id=$(cat loading-$user_id-$chat_id)
						loading 3
					;;
				esac
				cd "$basedir"
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
		"!rustc")
			if [[ $(is_status admins) ]]; then
				markdown=("<code>" "</code>")
				parse_mode=html
				twd
				printf '%s\n' "$(sed "s/$command//" <<< "${user_text}" | sed '/^$/d')" > "$user_id.rs"
				"$HOME/.cargo/bin/runner" "$user_id.rs" > out 2>&1
				if [[ "$?" == "0" ]]; then
					text_id=$(cat out)
				else
					text_id=$(cat out | sed -z "s|$HOME/.cargo/.runner/bin/||")
				fi
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
case_chat_id() {
	case "$chat_id" in
		-1001295527578|-1001402125530)
			if [[ "$(jshon -Q -e sender_chat <<< "$message")" == "" ]] \
			&& [[ "${message_id[1]}" == "" ]] \
			&& [[ "$chat_id" != "-1001402125530" ]]; then
				to_delete_id=$message_id
				tg_method delete_message
				ban_id=$user_id unban_id=$user_id
				tg_method ban_member
				to_delete_id=$(jshon -Q -e result -e message_id <<< "$curl_result")
				tg_method unban_member
				tg_method delete_message
			elif [[ "${message_id[1]}" != "" ]] \
			&& [[ "$(jshon -Q -e sender_chat <<< "$message")" == "" ]] \
			&& [[ "$(jshon -Q -e sender_chat <<< "${message_id[1]}")" != "" ]] \
			&& [[ "$user_id" != "160551211" ]] \
			&& [[ "$user_id" != "917684979" ]]; then
				text_id="https://t.me/c/$(tail -c +5 <<< "$chat_id")/$(jshon -Q -e message_id -u <<< "${message_id[1]}")/?comment=$message_id"
				chat_id="-1001312198683"
				tg_method send_message
			fi
		;;
		-1001332912452)
			if [[ "$user_text" != "" ]]; then
				message_link="https://t.me/c/$(tail -c +5 <<< "$chat_id")/$message_id/"
				text_id="Y-Hell: $message_link"
				o_chat_id=$chat_id
				chat_id="-1001067362020"
				tg_method send_message
				chat_id=$o_chat_id
			fi
		;;
		-1001497062361)
			case "$user_text" in
				"!rules"|"!regole"|"!lvx"|"!dvxtime"|"!dvxdocet"|"!dvxsofia")
					parse_mode=html
					markdown=("<a href=\"https://t.me/c/1497062361/38916\">" "</a>")
					text_id="Allora praticamente Sofia disse:"
					get_reply_id self
					tg_method send_message
				;;
			esac
		;;
	esac
}
case_user_id() {
	case "$user_id" in
		73520494) # lynn
			if [[ "$no_args" ]]; then
				users=$(cat lynnmentions | cut -f 1 -d :)
				mention=$(grep -oi "$(sed -e 's/^/\^/' -e 's/$/\$\\|/' <<< "$users" | tr '\n' ' ' | tr -d ' ' | head -c -2)" <<< "$user_text" | tr [[:upper:]] [[:lower:]])
				if [[ "$mention" ]]; then
					tag_id=$(grep "$mention" lynnmentions | cut -f 2 -d : | head -n 1)
					markdown=("<a href=\"tg://user?id=$tag_id\">" "</a>")
					parse_mode=html
					text_id=$mention
					get_reply_id self
					tg_method send_message
				fi
			fi
		;;
		492326133|160551211|917684979) # olibot
			case "$command" in
				"!olibot")
					case "${arg[0]}" in
						start|stop|restart|update)
							source ./olibot.sh "${arg[0]}"
							if [[ "$text_id" ]]; then
								get_reply_id self
								tg_method send_message
							fi
						;;
					esac
				;;
			esac
		;;
	esac
}

if [[ "$command" ]]; then
	case_command
else
	case_normal
fi
case_chat_id
case_user_id

case "$file_type" in
	"new_chat_members")
		if [[ "$(jshon -Q -e 0 -e id -u <<< "$new_members")" == "$(jshon -Q -e result -e id -u < botinfo)" ]]; then
			voice_id="https://archneek.zapto.org/webaudio/oh_my.ogg"
		else
			voice_id="https://archneek.zapto.org/webaudio/fanfare.ogg"
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
