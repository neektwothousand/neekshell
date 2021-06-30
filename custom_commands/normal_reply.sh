if [[ "$(grep "^chan_unpin" "db/chats/$chat_id")" ]]; then
	if [[ "$(jshon -Q -e sender_chat -e type -u <<< "$message")" == "channel" ]]; then
		curl -s "$TELEAPI/unpinChatMessage" --form-string "message_id=$message_id" --form-string "chat_id=$chat_id" > /dev/null
	fi
fi
case "$file_type" in
	sticker)
		sticker_unique_id=$(jshon -Q -e sticker -e file_unique_id -u <<< "$message")
		case "$sticker_unique_id" in
			AgADAwADf3BGHA) # https://t.me/addstickers/PoohSocialCredit
				normal_message="-20"
				lock_sticker="604800"
			;;
			AgADAgADf3BGHA) # https://t.me/addstickers/PoohSocialCredit
				normal_message="+20"
				lock_sticker="604800"
			;;
		esac
	;;
esac
case "$chat_id" in
	-1001295527578|-1001402125530)
		if [[ "$(jshon -Q -e sender_chat <<< "$message")" == "" ]] \
		&& [[ "$reply_to_message" == "" ]]; then
			to_delete_id=$message_id
			tg_method delete_message
			kick_id=$user_id unban_id=$user_id
			tg_method kick_member
			kick_message=$(jshon -Q -e result -e message_id <<< "$curl_result")
			tg_method unban_member
			to_delete_id=$kick_message
			tg_method delete_message
		elif [[ "$reply_to_message" != "" ]] \
		&& [[ "$(jshon -Q -e sender_chat <<< "$message")" == "" ]] \
		&& [[ "$user_id" != "160551211" ]] \
		&& [[ "$user_id" != "917684979" ]]; then
			text_id="https://t.me/c/$(tail -c +5 <<< "$chat_id")/$(jshon -Q -e message_id -u <<< "$reply_to_message")/?comment=$message_id"
			chat_id="-1001312198683"
			tg_method send_message
		fi
	;;
	-1001332912452)
		if [[ "$normal_message" != "" ]]; then
			message_link="https://t.me/c/$(tail -c +5 <<< "$chat_id")/$message_id/"
			text_id="Y-Hell: $message_link"
			o_chat_id=$chat_id
			chat_id="-1001067362020"
			tg_method send_message
			chat_id=$o_chat_id
		fi
	;;
	-1001497062361)
		case "$normal_message" in
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
case "$normal_message" in
	"!chat "*|"!chat"|"!start join"*)
		if [[ "$type" = "private" ]] || [[ $(is_admin) ]] ; then
			get_reply_id self
			case "${fn_arg[0]}" in
				"create")
					[[ ! -d $bot_chat_dir ]] && mkdir -p $bot_chat_dir
					if [[ "$(dir $bot_chat_dir | grep -o -- "$bot_chat_user_id")" = "" ]]; then
						file_bot_chat="$bot_chat_dir$bot_chat_user_id"
						[[ ! -e "$file_bot_chat" ]] && printf '%s\n' "users: " > "$file_bot_chat"
						text_id="your chat id: \"$bot_chat_user_id\""
					else
						text_id="you've already an existing chat"
					fi
				;;
				"delete")
					if [[ "$(dir $bot_chat_dir | grep -o -- "$bot_chat_user_id")" != "" ]]; then
						file_bot_chat="$bot_chat_dir$bot_chat_user_id"
						rm "$file_bot_chat"
						text_id="\"$bot_chat_user_id\" deleted"
					else
						text_id="you have not created any chat yet"
					fi
				;;
				"join"|"join"*)
					if [[ "$(grep -r -- "$bot_chat_user_id" "$bot_chat_dir")" = "" ]]; then
						case "${fn_arg[0]}" in
							"join")
								if [[ "$type" = "private" ]]; then
									text_id="Select chat to join:"
									num_bot_chat=$(ls -1 "$bot_chat_dir" | wc -l)
									list_bot_chat=$(ls -1 "$bot_chat_dir")
									for j in $(seq 0 $((num_bot_chat - 1))); do
										button_text[$j]=$(sed -n $((j+1))p <<< "$list_bot_chat")
									done
									markup_id=$(json_array inline button)
								elif [[ "$type" != "private" ]]; then
									if [[ $(is_admin) ]]; then
										join_chat=${fn_arg[1]}
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
								if [[ "$type" = "private" ]]; then
									join_chat=$(sed 's/.*join//' <<< "${fn_arg[0]}")
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
						if [[ "$type" = "private" ]]; then
							leave_chat=$(grep -r -- "$bot_chat_user_id" "$bot_chat_dir" | cut -d : -f 1 | cut -f 3 -d '/')
							text_id="Select chat to leave:"
							sed -i "s/$chat_id //" $bot_chat_dir"$leave_chat"
							text_id="$leave_chat is no more"
						elif [[ "$type" != "private" ]]; then
							if [[ $(is_admin) ]]; then
								leave_chat=${fn_arg[1]}
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
						text_id="number of active users: $(grep -r -- "$bot_chat_user_id" $bot_chat_dir | sed 's/.*:\s//' | tr ' ' '\n' | sed '/^$/d' | wc -l)"
					else
						text_id="you are not in any chat yet"
					fi
				;;
				"list")
					text_id=$(
						for c in $(seq "$(ls -1 "$bot_chat_dir" | wc -l)"); do
							bot_chat_id=$(ls -1 "$bot_chat_dir" | sed -n "${c}"p)
							bot_chat_users=$(sed 's/.*:\s//' "$bot_chat_dir$bot_chat_id" | tr ' ' '\n' | sed '/^$/d' | wc -l)
							printf '%s\n' "chat: $bot_chat_id users: $bot_chat_users"
						done
					)
					[[ "$text_id" = "" ]] && text_id="no chats found"
				;;
				*)
					text_id=$(cat help/chat)
					get_reply_id self
				;;
			esac
			tg_method send_message
		fi
	;;
	"!deemix "*|"!deemix")
		if [[ "$reply_to_text" != "" ]] || [[ "$fn_args" != "" ]]; then
			if [[ "$reply_to_text" != "" ]]; then
				deemix_link=$(grep -o 'https://www.deezer.*\|https://deezer.*' <<< "$reply_to_text" | cut -f 1 -d ' ')
			elif [[ "$fn_args" != "" ]]; then
				deemix_link=$fn_args
			fi
			if [[ "$(grep 'track\|album\|deezer.page.link' <<< "$deemix_link")" != "" ]]; then
				cd $tmpdir
				deemix_id=$RANDOM
				mkdir "$deemix_id" ; cd "$deemix_id"
				loading 1
				export LC_ALL=C.UTF-8
				export LANG=C.UTF-8
				~/.local/bin/deemix -b flac -p ./ "$deemix_link" 2>&1 > /dev/null
				downloaded=$(dir -N1)
				if [[ "$(dir -N1 "$downloaded" | wc -l)" -gt "1" ]]; then
					up_type=archive
					set +f
					zip "$downloaded.zip" "$downloaded/"* > /dev/null
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
				cd .. ; rm -rf "$deemix_id/"
				cd "$basedir"
			fi
		else
			text_id=$(cat help/deemix)
			get_reply_id self
			tg_method send_message
		fi
	;;
	"!d "*|"!dice "*|"!d"|"!dice")
		get_reply_id self
		case "$fn_args" in
			[0-9]*|[0-9]*"*"[0-9]*)
				if [[ "$(grep "*" <<< "$normal_message")" != "" ]]; then
					normaldice=$(sed "s/!d//" <<< "$normal_message" | cut -d "*" -f 1)
					mul=$(sed "s/!d//" <<< "$normal_message" | cut -d "*" -f 2)
				else
					normaldice=$(sed "s/!d//" <<< "$normal_message")
					mul=1
				fi
				for x in $(seq "$mul"); do
					chars=$(( $(wc -m <<< "$normaldice") - 1 ))
					result[$x]=$(( ($(cat /dev/urandom | tr -dc '[:digit:]' 2>/dev/null | head -c $chars) % $normaldice) + 1 ))
				done
				text_id=${result[*]}
				markdown=("<code>" "</code>")
				parse_mode=html
				tg_method send_message
			;;
			*)
				text_id=$(cat help/dice)
				tg_method send_message
			;;
		esac
	;;
	"!fortune"|"!fortune "*)
		if [[ "$fn_args" = "" ]]; then
			text_id=$(/usr/bin/fortune fortunes paradoxum goedel linuxcookie | tr '\n' ' ' | awk '{$2=$2};1')
		else
			text_id=$(/usr/bin/fortune "$fn_args" | tr '\n' ' ' | awk '{$2=$2};1')
		fi
		if [[ "$text_id" != "" ]]; then
			get_reply_id any
			tg_method send_message
		else
			get_reply_id self
			text_id=$(cat help/fortune)
			tg_method send_message
		fi
	;;
	"!gayscale"|"!gs")
		if [[ "$reply_to_user_id" = "" ]]; then
			gs_id=$user_id
			gs_fname=$user_fname
		else
			gs_id=$reply_to_user_id
			gs_fname=$reply_to_user_fname
		fi
		[[ ! -d .lock+/gs/ ]] && mkdir -p .lock+/gs/
		lockfile=.lock+/gs/"$gs_id"-lock
		# check if it's younger than one day
		lock_age=$(bc <<< "$(date +%s) - $(stat -c "%W" $lockfile)")
		if [[ -e $lockfile ]] && [[ $lock_age -lt 86400 ]]; then
			gs_perc=$(grep "^gs: " db/users/"$gs_id" | sed 's/gs: //')
			if [[ $gs_perc -gt 9 ]]; then
				for x in $(seq $((gs_perc/10))); do
					rainbow="🏳️‍🌈${rainbow}"
				done
			fi
			text_id="$gs_fname is ${gs_perc}% gay $rainbow"
		else
			rm $lockfile
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
			prev_gs=$(grep "^gs: " db/users/"$gs_id" | sed 's/gs: //')
			if [[ "$prev_gs" = "" ]]; then
				printf '%s\n' "gs: 0" >> db/users/"$gs_id"
			fi
			sed -i "s/^gs: .*/gs: ${gs_perc}/" db/users/"$gs_id"
			touch $lockfile
		fi
		get_reply_id any
		tg_method send_message
	;;
	"!hf")
		randweb=$(( ( RANDOM % 4 ) +1))
		get_reply_id self
		case $randweb in
			1)
				popfeat=$(wget -q -O- "https://www.hentai-foundry.com/pictures/random/?enterAgree=1" | \
					grep -io '<div class="thumbTitle"><a href=['"'"'"][^"'"'"']*['"'"'"]' | \
					sed -e 's/^<div class="thumbTitle"><a href=["'"'"']//i' -e 's/["'"'"']$//i')
				hflist=$(sort -t / -k 5 <<< "$popfeat")
				counth=$(wc -l <<< "$hflist")
				while [[ "$x" -le "5" ]]; do
					x=$((x+1))
					randh=$(sed -n "$(( ( RANDOM % counth ) + 1 ))p" <<< "$hflist")
					wgethf=$(wget -q -O- "https://www.hentai-foundry.com$randh/?enterAgree=1")
					photo_id=$(sed -n 's/.*src="\([^"]*\)".*/\1/p' <<< "$wgethf" | \
						grep "pictures.hentai" | \
						sed "s/^/https:/")
					caption="https://www.hentai-foundry.com$randh"
					tg_method send_photo
					[[ "$(jshon -Q -e ok -u <<< "$curl_result")" = "true" ]] && break
				done
			;;
			2)
				while [[ "$x" -le "5" ]]; do
					x=$((x+1))
					randh=$(wget -q -O- 'https://rule34.xxx/index.php?page=post&s=random')
					photo_id=$(grep 'content="https://img.rule34.xxx\|content="https://himg.rule34.xxx' <<< "$randh" \
						| sed -En 's/.*content="(.*)"\s.*/\1/p')
					caption="https://rule34.xxx/index.php?page=post&s=view&$(grep 'action="index.php?' <<< "$randh" \
					| sed -En 's/.*(id=.*)&.*/\1/p')"
					tg_method send_photo
					[[ "$(jshon -Q -e ok -u <<< "$curl_result")" = "true" ]] && break
				done
			;;
			3)
				while [[ "$x" -le "5" ]]; do
					x=$((x+1))
					randh=$(wget -q -O- 'https://safebooru.org/index.php?page=post&s=random')
					photo_id=$(grep 'content="https://safebooru.org' <<< "$randh" \
						| sed -En 's/.*content="(.*)"\s.*/\1/p')
					caption="https://safebooru.org/index.php?page=post&s=view&$(grep '<form method="post" action="index.php?' <<< "$randh" \
						| sed -En 's/.*(id=.*)&.*/\1/p')"
					tg_method send_photo
					[[ "$(jshon -Q -e ok -u <<< "$curl_result")" = "true" ]] && break
				done
			;;
			4)
				while [[ "$x" -le "5" ]]; do
					x=$((x+1))
					randh=$(wget -q -O- 'https://gelbooru.com/index.php?page=post&s=random')
					photo_id=$(grep 'content="https://img2' <<< "$randh" \
						| sed -En 's/.*content="(.*)"\s.*/\1/p')
					caption="https://gelbooru.com/index.php?page=post&s=view&$(grep '<form method="post" action="index.php' <<< "$randh" \
						| sed -En 's/.*(id=.*)&.*/\1/p')"
					tg_method send_photo
					[[ "$(jshon -Q -e ok -u <<< "$curl_result")" = "true" ]] && break
				done
			;;
		esac
	;;
	"!insta "*|"!insta")
		if [[ "$fn_args" != "" ]]; then
			if [[ "$(grep '^@' <<< "$fn_args")" != "" ]]; then
				fn_arg=${fn_arg/@/}
			fi
			if [[ "$(grep '[^_.a-zA-Z]' <<< "$fn_args")" != "" ]]; then
				return
			fi
			loading 1
			ig_user=$(sed -n 1p ig_key)
			ig_pass=$(sed -n 2p ig_key)
			cd $tmpdir
			request_id="${fn_arg}_${chat_id}"
			[[ ! -d "$request_id" ]] && mkdir "$request_id"
			cd "$request_id"
			ig_scraper=$(~/.local/bin/instagram-scraper -u $ig_user -p $ig_pass -m 50 "$fn_args")
			if [[ "$(grep "^ERROR" <<< "$ig_scraper")" != "" ]]; then
				loading 3
				return
			fi
			loading 2
			ls -t -1 "$fn_args" > ig_list
			printf '%s' "$user_id" > ig_userid
			if [[ "$(sed -n 2p ig_list)" != "" ]]; then
				button_text=(">")
				button_data=("insta + $fn_args $chat_id")
				markup_id=$(json_array inline button)
			fi
			printf '%s' "1" > ig_page
			media_id="@$(sed -n 1p ig_list)"
			ext=$(grep -o "...$" <<< "$media_id")
			cd "$fn_args"
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
			cd ..
			printf '%s' "$ig_id" > ig_id
			cd "$basedir"
		else
			text_id=$(cat help/insta)
			get_reply_id self
			tg_method send_message
		fi
	;;
	"!jpg")
		if [[ "$reply_to_id" != "" ]]; then
			cd $tmpdir
			request_id=$RANDOM
			get_reply_id reply
			get_file_type reply
			case $file_type in
				text)
					list_char[0]=$(sed -E 's/(.)/\1 /g' <<< "$reply_to_text" | tr -s ' ' | tr ' ' '\n' | sort -u | sed '/^$/d' | sort -R | tr '\n' ' ' | tr -d ' ')
					list_char[1]=$(sed -E 's/(.)/\1 /g' <<< "$reply_to_text" | tr -s ' ' | tr ' ' '\n' | sort -u | sed '/^$/d' | sort -R | tr '\n' ' ' | tr -d ' ')
					text_id=$(sed "y/${list_char[0]}/${list_char[1]}/" <<< "$reply_to_text")
					tg_method send_message
				;;
				photo)
					file_path=$(curl -s "${TELEAPI}/getFile" --form-string "file_id=$media_id" | jshon -Q -e result -e file_path -u)
					ext=$(sed 's/.*\.//' <<< "$file_path")
					if [[ "$(grep "png\|jpg\|jpeg" <<< "$ext")" != "" ]]; then
						case "$ext" in
							png)
								convert "$file_path" "pic-$request_id.jpg"
								ext=jpg
							;;
							jpg|jpeg)
								cp "$file_path" "pic-$request_id.jpg"
							;;
						esac
						res=($(ffprobe -v error -show_streams "pic-$request_id.$ext" | sed -n -e 's/^width=\(.*\)/\1/p' -e 's/^height=\(.*\)/\1/p'))
						magick "pic-$request_id.$ext" -resize $(bc <<< "${res[0]}/1.5")x$(bc <<< "${res[1]}/1.5") "pic-$request_id.$ext"
						magick "pic-$request_id.$ext" -quality 6 "pic-$request_id.$ext"
						photo_id="@pic-$request_id.$ext"
						tg_method send_photo upload
						rm "pic-$request_id.$ext"
					fi
				;;
				sticker)
					file_path=$(curl -s "${TELEAPI}/getFile" --form-string "file_id=$sticker_id" | jshon -Q -e result -e file_path -u)
					cp "$file_path" "sticker-$request_id.webp"
					res=($(ffprobe -v error -show_streams "sticker-$request_id.webp" | sed -n -e 's/^width=\(.*\)/\1/p' -e 's/^height=\(.*\)/\1/p'))
					convert "sticker-$request_id.webp" "sticker-$request_id.jpg"
					magick "sticker-$request_id.jpg" -resize $(bc <<< "${res[0]}/1.5")x$(bc <<< "${res[1]}/1.5") "sticker-$request_id.jpg"
					magick "sticker-$request_id.jpg" -quality 6 "sticker-$request_id.jpg"
					magick "sticker-$request_id.jpg" -resize 512x512 "sticker-$request_id.jpg"
					convert "sticker-$request_id.jpg" "sticker-$request_id.webp"
					
					sticker_id="@sticker-$request_id.webp"
					tg_method send_sticker upload
					
					rm "sticker-$request_id.webp" \
						"sticker-$request_id.jpg"
				;;
				video|animation)
					if [[ "$file_type" == "video" ]]; then
						media_id=$video_id
					elif [[ "$file_type" == "animation" ]]; then
						media_id=$animation_id
					fi
					file_path=$(curl -s "${TELEAPI}/getFile" --form-string "file_id=$media_id" | jshon -Q -e result -e file_path -u)
					ext=$(sed 's/.*\.//' <<< "$file_path")
					if [[ "$ext" == "gif" ]]; then
						ffmpeg -i "$file_path" "video-$request_id.mp4"
					else
						cp "$file_path" "video-$request_id.mp4"
					fi
					loading 1
					res=($(ffprobe -v error -show_streams "video-$request_id.mp4" | sed -n -e 's/^width=\(.*\)/\1/p' -e 's/^height=\(.*\)/\1/p'))
					res[0]=$(bc <<< "${res[0]}/1.5")
					res[1]=$(bc <<< "${res[1]}/1.5")
					[[ "$((${res[0]}%2))" -eq "0" ]] || res[0]=$((${res[0]}-1))
					[[ "$((${res[1]}%2))" -eq "0" ]] || res[1]=$((${res[1]}-1))
					if [[ "$file_type" == "video" ]]; then
						ffmpeg -i video-"$request_id".mp4 \
							-vf "scale=${res[0]}:${res[1]}" -sws_flags fast_bilinear \
							-crf 50 -c:a aac -b:a 24k video-low-"$request_id".mp4
						loading 2
						video_id="@video-low-$request_id.mp4"
						tg_method send_video upload
					else
						ffmpeg -i video-"$request_id".mp4 \
							-vf "scale=${res[0]}:${res[1]}" -sws_flags fast_bilinear \
							-crf 50 -an video-low-"$request_id".mp4
						loading 2
						animation_id="@video-low-$request_id.mp4"
						tg_method send_animation upload
					fi
					loading 3
					rm video-"$request_id".mp4 video-low-"$request_id".mp4
				;;
				audio)
					file_path=$(curl -s "${TELEAPI}/getFile" --form-string "file_id=$audio_id" | jshon -Q -e result -e file_path -u)
					ext=$(sed 's/.*\.//' <<< "$file_path")
					cp "$file_path" "audio-$request_id.$ext"
					loading 1
					ffmpeg -i audio-"$request_id".$ext -vn -acodec libmp3lame -b:a 6k audio-low-"$request_id".mp3
					loading 2
					audio_id="@audio-low-$request_id.mp3"
					tg_method send_audio upload
					loading 3
					rm audio-"$request_id".$ext audio-low-"$request_id".mp3
				;;
				voice)
					file_path=$(curl -s "${TELEAPI}/getFile" --form-string "file_id=$voice_id" | jshon -Q -e result -e file_path -u)
					cp "$file_path" "voice-$request_id.ogg"
					loading 1
					ffmpeg -i voice-"$request_id".ogg -vn -acodec opus -b:a 6k -strict -2 voice-low-"$request_id".ogg
					loading 2
					voice_id="@voice-low-$request_id.ogg"
					tg_method send_voice upload
					loading 3
					rm voice-"$request_id".ogg voice-low-"$request_id".ogg
				;;
			esac
			cd "$basedir"
		else
			text_id=$(cat help/jpg)
			get_reply_id self
			tg_method send_message
		fi
	;;
	"!json")
		cd $tmpdir
		update_id="${message_id}${user_id}"
		printf '%s' "$input" | sed -e 's/{"/{\n"/g' -e 's/,"/,\n"/g' > decode-$update_id.json
		document_id=@decode-$update_id.json
		get_reply_id any
		tg_method send_document upload
		rm decode-$update_id.json
		cd "$basedir"
	;;
	"!me"|"!me "*)
		if [[ "$fn_args" != "" ]]; then
			text_id="> $user_fname $fn_args"
			tg_method send_message
			to_delete_id=$message_id
			tg_method delete_message
		else
			get_reply_id self
			text_id=$(cat help/me)
			tg_method send_message
		fi
	;;
	"!my "*)
		get_reply_id self
		case "$fn_args" in
			+|rep)
				top_info="totalrep"
			;;
			gs|gayscale)
				top_info="gs"
			;;
			*)
				text_id=$(cat help/my)
				tg_method send_message
				return
			;;
		esac
		user_info=$(grep "^fname\|^lname\|^$top_info" "$file_user")
		if [[ "$top_info" == "totalrep" ]]; then
			p_rep_list=$(grep "^rep" "$file_user")
			for x in $(seq $(wc -l <<< "$p_rep_list")); do
				p_rep_fname=$(grep '^fname' db/users/"$(sed -n ${x}p <<< "$p_rep_list" | sed -e "s/^rep-//" -e "s/:.*//")" \
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
	"!nh "*)
		get_reply_id self
		cd $tmpdir
		nhentai_id=$(cut -d / -f 5 <<< "$fn_args")
		nhentai_check=$(wget -q -O- "https://nhentai.net/g/$nhentai_id/1/")
		loading 1
		if [[ "$nhentai_check" != "" ]]; then
			request_id=$RANDOM
			mkdir "$request_id" ; cd "$request_id"
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
			json_array telegraph
			text_id=$(curl -s "$GRAPHAPI/createPage" -X POST -H 'Content-Type: application/json' \
				-d "{\"access_token\":\"$GRAPHTOKEN\",\"title\":\"$graph_title\",\"content\":${graph_content}}" \
				| jshon -Q -e result -e url -u)
			loading 3
			tg_method send_message
			cd .. ; rm -rf "$request_id/"
		else
			loading value "invalid id"
		fi
		cd "$basedir"
	;;
	"!owoifer"|"!owo"|"!cringe")
		reply=$(jshon -Q -e reply_to_message -e text -u <<< "$message")
		if [[ "$reply" != "" ]]; then
			numberspace=$(tr -dc ' ' <<< "$reply" | wc -c)
			
			[[ "$numberspace" -eq "0" ]] && reply="$reply " && numberspace=1
			
			case $normal_message in
				"!cringe")
					owoarray=("🥵" "🙈" "🤣" "😘" "🥺" "💁‍♀️" "😳" "🤠" "🤪" "😜" "🤬" "🤧" "🦹‍♂" "🍌" "😏" "😒" "😎" "🙄" "🧐" "😈" "👐🏻" "👏🏻" "👀" "👅" "🍆" "🤢" "🤮" "🤡" "💯" "👌" "😂" "🅱️" "💦")
				;;
				"!owoifer"|"!owoifier"|"!owo")
					owoarray=("owo" "ewe" "uwu" ":3" "x3")
				;;
			esac
			
			for x in $(seq $(((numberspace / 16)+1))); do
				reply=$(sed "s/\s/ ${owoarray[$((RANDOM % ${#owoarray[@]}))]} /$(((RANDOM % numberspace)+1))" <<< "$reply")
			done
			
			text_id=$(sed -e 's/[lr]/w/g' -e 's/[LR]/W/g' <<< "$reply")
			get_reply_id reply
		else
			text_id=$(cat help/owo)
			get_reply_id self
		fi
		if [[ "$reply_to_user_id" = "$(jshon -Q -e result -e id -u < botinfo)" ]]; then
			edit_id=$reply_to_id
			edit_text=$text_id
			tg_method edit_text
		else
			tg_method send_message
		fi
	;;
	"!ping")
		text_id=$(printf '%s\n' "pong" ; ping -c 1 192.168.1.15 | grep time= | sed 's/.*time=//')
		get_reply_id self
		tg_method send_message
	;;
	"!reddit "*|"!reddit")
		get_reply_id self
		if [[ "$fn_args" != "" ]]; then
			subreddit=$(cut -f 1 -d ' ' <<< "$fn_args")
			filter=$(cut -f 2 -d ' ' <<< "$fn_args")
			source bin/r_subreddit.sh "$subreddit" "$filter"
		else
			text_id=$(cat help/reddit)
			tg_method send_message
		fi
	;;
	"!sed "*|"!sed")
		[[ "$reply_to_caption" != "" ]] && reply_to_text=$reply_to_caption
		if [[ "$reply_to_text" != "" ]]; then
			if [[ "$(cut -f 1 -d '/' <<< "$fn_args" | grep 'e')" == "" ]]; then
				regex=$fn_args
				text_id=$(sed "$regex" <<< "$reply_to_text")
				get_reply_id reply
			fi
		else
			text_id=$(cat help/sed)
			get_reply_id self
		fi
		tg_method send_message
	;;
	"!stats "*|"!stats")
		source bin/stats.sh
		get_reply_id self
		if [[ "$photo_id" == "" ]]; then
			text_id="stats not found"
			tg_method send_message
		else
			tg_method send_photo upload
		fi
		cd "$basedir"
	;;
	"!tag"|"!tag "*)
		if [[ "$reply_to_text" = "" ]]; then
			text_id=$(cut -f 2- -d ' ' <<< "$fn_args")
		else
			text_id=$reply_to_text
		fi
		tag_name=$(cut -f 1 -d ' ' <<< "$fn_args")
		if [[ $tag_name = [0-9]* ]]; then
			tag_id=$tag_name
		else
			tag_id=$(grep '^id:' $(grep -ri -- "$(sed 's/@//' <<< "$tag_name")" db/users/ | cut -d : -f 1) | head -n 1 | sed 's/.*id: //')
		fi
		if [[ "$text_id" = "" ]]; then
			text_id=$(cat help/tag)
			get_reply_id self
		elif [[ "$tag_id" = "" ]]; then
			text_id="$tag_name not found"
		elif [[ "$tag_id" != "" ]] && [[ "$text_id" != "" ]]; then
			markdown=("<a href=\"tg://user?id=$tag_id\">" "</a>")
			parse_mode=html
		fi
		tg_method send_message
	;;
	"!text2img"|"!text2img "*)
		get_reply_id self
		if [[ "$reply_to_text" != "" ]]; then
			text2img=$reply_to_text
		else
			text2img=$fn_args
			[[ "$fn_args" = "$normal_message" ]] && text2img=""
		fi
		if [[ "$text2img" != "" ]]; then
			api_key=$(cat deepai_key)
			photo_id=$(curl -s "https://api.deepai.org/api/text2img" \
				-F "text=$text2img" \
				-H "api-key:$api_key" | jshon -e output_url -u)
			tg_method send_photo
		else
			text_id=$(cat help/text2img)
			get_reply_id self
			tg_method send_message
		fi
	;;
	"!top "*)
		get_reply_id self
		case "$fn_args" in
			+|rep)
				top_info="totalrep"
			;;
			gs|gayscale)
				top_info="gs"
			;;
			*)
				text_id=$(cat help/top)
				tg_method send_message
				return
			;;
		esac
		list_top=$(grep -r "^$top_info" db/users/ | cut -d : -f 1)
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
	"!trad"|"!trad "*)
		if [[ "$reply_to_text" ]]; then
			to_trad=$reply_to_text
		elif [[ "$reply_to_caption" ]]; then
			to_trad=$reply_to_caption
		elif [[ "$fn_args" ]]; then
			to_trad=$fn_args
		fi
		if [[ "$to_trad" ]]; then
			text_id=$(trans :en -j -b "$to_trad")
			get_reply_id self
			tg_method send_message
		fi
	;;
	"!tuxi "*)
		text_id=$(PATH=~/go/bin:~/.local/bin:$PATH tuxi -q -r -- "$fn_args")
# 		if [[ $? != 0 ]]; then
# 			query=$(sed -n 's/> did you mean "\(.*\)".*/\1/p' <<< "$text_id")
# 			text_id=$(PATH=~/go/bin:~/.local/bin:$PATH tuxi -r -- "$query")
# 		fi
		get_reply_id self
		tg_method send_message
	;;
	"!ytdl "*|"!ytdl")
		get_reply_id self
		cd $tmpdir
		if [[ "$reply_to_text" != "" ]]; then
			ytdl_link=$reply_to_text
		else
			ytdl_link=$fn_args
		fi
		ytdl_link=$(sed -e 's/.*\(https\)/\1/' -e 's/ .*//' <<< "$ytdl_link")
		if [[ "$ytdl_link" != "" ]]; then
			ytdl_id=$RANDOM
			loading 1
			ytdl_json=$(youtube-dl --print-json --merge-output-format mp4 -o ytdl-$ytdl_id.mp4 "$ytdl_link")
			if [[ "$ytdl_json" != "" ]]; then
				caption=$(jshon -Q -e title -u <<< "$ytdl_json")
				if [[ "$(du -m ytdl-$ytdl_id.mp4 | cut -f 1)" -ge 2000 ]]; then
					loading value "error"
					rm ytdl-$ytdl_id.mp4
				else
					video_id="@ytdl-$ytdl_id.mp4" thumb="@thumb-$ytdl_id.jpg"
					loading 2
					tg_method send_video upload
					loading 3
					rm "ytdl-$ytdl_id.mp4" "thumb-$ytdl_id.jpg"
				fi
			else
				loading value "error"
			fi
		fi
		cd "$basedir"
	;;
	
	## administrative commands
	
	"!flush")
		get_member_id=$user_id
		tg_method get_chat_member
		if [[ "$(jshon -Q -e result -e status -u <<< "$curl_result" | grep -w "creator\|administrator")" != "" ]] \
		&& [[ "$reply_to_message" != "" ]]; then
			text_id="flushing..."
			tg_method send_message
			flush_id=$(jshon -Q -e result -e message_id -u <<< "$curl_result")
			for x in $(seq "$message_id" -1 "$reply_to_id"); do
				to_delete_id=$x
				tg_method delete_message &
				sleep 0.1
			done
			to_delete_id=$flush_id
			tg_method delete_message
		fi
	;;
	"!db "*)
		if [[ $(is_admin) ]]; then
			case "${fn_arg[0]}" in
				"chats")
					unset text_id
					for x in $(seq $(dir -1 db/chats/ | wc -l)); do
						info_chat=$(dir -1 db/chats/ | sed -n ${x}p)
						count[$x]=$(curl -s "$TELEAPI/getChatMembersCount" --form-string "chat_id=$info_chat" | jshon -Q -e result -u)
						info[$x]="${count[$x]} members, $(cat -- db/chats/"$info_chat" | sed -e 's/^title: //' -e '2d' -e 's/^type:/,/' | tr -d '\n')"
						if [[ "${count[$x]}" = "" ]]; then
							unset info[$x]
							rm -f -- db/chats/"$info_chat"
						fi
					done
					text_id=$(printf '%s\n' "${info[@]}" | sort -nr)
					get_reply_id any
					tg_method send_message
				;;
				"get")
					if [[ "$reply_to_user_id" != "" ]]; then
						text_id=$(cat db/users/"$reply_to_user_id")
						get_reply_id any
						tg_method send_message
					fi
			esac
		fi
	;;
	"!set "*)
		if [[ $(is_admin) ]]; then
			set_username=$(sed 's/^@//' <<< "${fn_arg[1]}")
			set_file=$(grep -ir -- "$set_username" db/users/ | head -n 1 | cut -d : -f 1)
			set_id=$(grep '^id' "$set_file" | sed 's/^id: //')
			if [[ "$set_id" != "" ]]; then
				case "${fn_arg[0]}" in
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
	"!bin "*|"!archbin "*)
		markdown=("<code>" "</code>")
		parse_mode=html
		if [[ $(grep "160551211\|917684979" <<< "$user_id") ]]; then
			case "$normal_message" in
				"!bin "*)
					text_id=$(mksh -c "$fn_args" 2>&1)
				;;
				"!archbin "*)
					text_id=$(ssh neek@192.168.1.35 -p 24 "$fn_args")
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
	"!nhzip "*)
		get_reply_id self
		if [[ $(is_admin) ]]; then
			cd $tmpdir
			nhentai_id=$(cut -d / -f 5 <<< "$fn_args")
			nhentai_check=$(wget -q -O- "https://nhentai.net/g/$nhentai_id/1/")
			if [[ "$nhentai_check" != "" ]]; then
				loading 1
				nhzip_id=$RANDOM
				nhentai_title=$(wget -q -O- "https://nhentai.net/g/$nhentai_id" \
					| grep 'meta itemprop="name"' \
					| sed -e 's/.*<meta itemprop="name" content="//' -e 's/".*//' \
					| sed -e 's/[[:punct:]]//g' -e 's/\s/_/g')
				numpages=$(grep 'num-pages' <<< "$nhentai_check" \
					| sed -e 's/.*<span class="num-pages">//' -e 's/<.*//')
				nhentai_ext=$(grep 'img src' <<< "$nhentai_check" \
					| sed -e 's/.*<img src="//' -e 's/".*//' \
					| sed 's/.*\.//')
				mkdir "nhentai-$nhzip_id"
				for x in $(seq $numpages); do
					nhentai_pic=$(wget -q -O- "https://nhentai.net/g/$nhentai_id/$x/" \
						| grep 'img src' \
						| sed -e 's/.*<img src="//' -e 's/".*//')
					wget -q -O "nhentai-$nhzip_id/pic-$x.$nhentai_ext" "$nhentai_pic"
				done
				set +f
				zip "$nhentai_title-$nhzip_id.zip" "nhentai-$nhzip_id/"* > /dev/null
				set -f
				rm -r "nhentai-$nhzip_id"
				if [[ "$(du -m "$nhentai_title-$nhzip_id.zip" | cut -f 1)" -ge 2000 ]]; then
					zip_list=$(zipsplit -qn 51380220 "$nhentai_title-$nhzip_id.zip" | grep creating | sed 's/creating: //')
					zip_num=$(wc -l <<< "$zip_list")
					loading 2
					for x in $(seq $zip_num); do
						zip_file=$(sed -n ${x}p <<< "$zip_list")
						document_id="@$zip_file"
						tg_method send_document upload
						rm "$zip_file"
					done
					loading 3
				else
					document_id="@$nhentai_title-$nhzip_id.zip"
					loading 2
					tg_method send_document upload
					loading 3
					rm "$nhentai_title-$nhzip_id.zip"
				fi
			else
				text_id="invalid id"
				tg_method send_message
			fi
			cd "$basedir"
		else
			markdown=("<code>" "</code>")
			parse_mode=html
			text_id="Access denied"
			tg_method send_message
		fi
	;;
	"!explorer "*)
		if [[ $(is_admin) ]] && [[ "$type" = "private" ]]; then
			get_reply_id self
			selected_dir=$(sed 's|/$||' <<< "$fn_args")
			files_selected_dir=$(dir -N1 --file-type -- "$selected_dir" | sed '/\/$/d')
			text_id=$(printf '%s\n' "selected directory: $selected_dir" \
					"select a file to download" "subdirs:" \
					; dir -N1 --file-type -- "$selected_dir" | sed -n '/\/$/p')
			if [[ "$files_selected_dir" != "" ]]; then
				for j in $(seq 0 $(( $(wc -l <<< "$files_selected_dir") -1 )) ); do
					button_text[$j]=$(sed -n $((j+1))p <<< "$files_selected_dir")
					button_data[$j]="$((j+1))"
				done
				markup_id=$(json_array inline button)
			fi
		else
			markdown=("<code>" "</code>")
			parse_mode=html
			text_id="Access denied"
		fi
		tg_method send_message
	;;
	"!broadcast "*|"!broadcast")
		if [[ $(is_admin) ]]; then
			listchats=$(printf '%s\n' "$(grep -r users db/bot_chats/ | sed 's/.*: //' | tr ' ' '\n' | sed '/^$/d')" "$(dir -1 db/chats/)" | sort -u | grep -vw -- "$chat_id")
			numchats=$(wc -l <<< "$listchats")
			br_delay=1
			if [[ "$fn_args" != "" ]]; then
				text_id=$fn_args
				for x in $(seq "$numchats"); do
					chat_id=$(sed -n ${x}p <<< "$listchats")
					tg_method send_message
					sleep $br_delay
				done
			elif [[ "$reply_to_message" != "" ]]; then
				from_chat_id=$chat_id
				copy_id=$reply_to_id
				for x in $(seq "$numchats"); do
					chat_id=$(sed -n ${x}p <<< "$listchats")
					tg_method copy_message
					sleep $br_delay
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
	"!nomedia")
		if [[ "$type" != "private" ]] && [[ $(is_admin) ]]; then
		get_reply_id self
		current_send_media=$(curl -s "${TELEAPI}/getChat" --form-string "chat_id=$chat_id" | jshon -Q -e result -e permissions -e can_send_media_messages -u)
			if [[ "$current_send_media" = "true" ]]; then
				can_send_messages="true"
				can_send_media_messages="false"
				can_send_other_messages="false"
				can_send_polls="false"
				can_add_web_page_previews="false"
				
				tg_method set_chat_permissions
				set_chat_permissions=$(jshon -Q -e ok -u <<< "$curl_result")
				
				if [[ "$set_chat_permissions" = "true" ]]; then
					text_id="no-media mode activated, send again to deactivate"
				else
					text_id="error: bot is not admin"
				fi
			else
				can_send_messages="true"
				can_send_media_messages="true"
				can_send_other_messages="true"
				can_send_polls="true"
				can_add_web_page_previews="true"
				
				tg_method set_chat_permissions
				set_chat_permissions=$(jshon -Q -e ok -u <<< "$curl_result")
				
				if [[ "$set_chat_permissions" = "true" ]]; then
					text_id="no-media mode deactivated"
				else
					text_id="error: bot is not admin"
				fi
			fi
			tg_method send_message
		else
			markdown=("<code>" "</code>")
			parse_mode=html
			text_id="Access denied"
			tg_method send_message
		fi
	;;
	"!silence")
		if [[ "$type" != "private" ]] && [[ $(is_admin) ]]; then
		get_reply_id self
		current_send_messages=$(curl -s "${TELEAPI}/getChat" --form-string "chat_id=$chat_id" | jshon -Q -e result -e permissions -e can_send_messages -u)
			if [[ "$current_send_messages" = "true" ]]; then
				can_send_messages="false"
				can_send_media_messages="false"
				can_send_other_messages="false"
				can_send_polls="false"
				can_add_web_page_previews="false"
				
				tg_method set_chat_permissions
				set_chat_permissions=$(jshon -Q -e ok -u <<< "$curl_result")
				
				if [[ "$set_chat_permissions" = "true" ]]; then
					text_id="read-only mode activated, send again to deactivate"
				else
					text_id="error: bot is not admin"
				fi
			else
				can_send_messages="true"
				can_send_media_messages="true"
				can_send_other_messages="true"
				can_send_polls="true"
				can_add_web_page_previews="true"
				
				tg_method set_chat_permissions
				set_chat_permissions=$(jshon -Q -e ok -u <<< "$curl_result")
				
				if [[ "$set_chat_permissions" = "true" ]]; then
					text_id="read-only mode deactivated"
				else
					text_id="error: bot is not admin"
				fi
			fi
			tg_method send_message
		else
			markdown=("<code>" "</code>")
			parse_mode=html
			text_id="Access denied"
			tg_method send_message
		fi
	;;
	"!del"|"!delete")
		if [[ $(is_admin) ]]; then
			to_delete_id=$reply_to_id
			tg_method delete_message
		fi
	;;
	"!loading "*)
		if [[ $(is_admin) ]]; then
			cd $tmpdir
			case "$fn_args" in
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
	"!warn "*|"!warn"|"!ban "*|"!ban"|"!kick "*|"!kick")
		get_member_id=$user_id
		tg_method get_chat_member
		if [[ "$(jshon -Q -e result -e status -u <<< "$curl_result" | grep -w "creator\|administrator")" != "" ]]; then
			if [[ "$reply_to_user_id" != "" ]]; then
				if [[ "$reply_to_user_id" == "$user_id" ]]; then
					return # if reply is self return
				else
					restrict_id=$reply_to_user_id
				fi
			elif [[ "${fn_arg[0]}" != "" ]]; then
				if [[ "${fn_arg[0]}" != [0-9]* ]]; then
					restrict_id=$(grep '^id:' $(grep -ri -- "$(sed 's/@//' <<< "${fn_arg[0]}")" db/users/ | cut -d : -f 1) | head -n 1 | sed 's/.*id: //')
				else
					restrict_id=${fn_arg[0]}
				fi
				if [[ "$restrict_id" == "$user_id" ]]; then
					return # if id argument is self return
				fi
			else
				return # if no reply nor argument provided, return
			fi
			if [[ "$reply_to_user_fname" == "" ]]; then
				restrict_fname=$(grep -w -- "^fname" db/users/"$restrict_id" | sed 's/.*fname: //')
			else
				restrict_fname=$reply_to_user_fname
			fi
			get_member_id=$restrict_id
			tg_method get_chat_member
			if [[ "$(jshon -Q -e ok -u <<< "$curl_result")" == "false" ]]; then
				return # if cannot find user in chat return
			fi
			get_member_id=$(jshon -Q -e result -e id -u < botinfo)
			tg_method get_chat_member
			if [[ "$(jshon -Q -e result -e status -u <<< "$curl_result" | grep -w "creator\|administrator")" != "" ]]; then
				case "$normal_message" in
					"!warn "*|"!warn")
						warns=$(grep "^warns-$chat_id:" db/users/"$restrict_id" | sed 's/.*: //')
						if [[ "$warns" == "" ]]; then
							warns=1
							printf '%s\n' "warns-$chat_id: $warns" >> db/users/"$restrict_id"
						elif [[ "$warns" -eq "1" ]]; then
							warns=$(($warns+1))
							sed -i "s/^warns-$chat_id: .*/warns-$chat_id: $warns/" db/users/"$restrict_id"
						elif [[ "$warns" -eq "2" ]]; then
							warns=$(($warns+1))
							sed -i "s/^warns-$chat_id: .*//" db/users/"$restrict_id"
							sed -i '/^$/d' db/users/"$restrict_id"
							can_send_messages="false"
							can_send_media_messages="false"
							can_send_other_messages="false"
							can_send_polls="false"
							can_add_web_page_previews="false"
							tg_method restrict_member
						fi
						if [[ "$(jshon -Q -e ok -u <<< "$curl_result")" != "false" ]]; then
							text_id="$restrict_fname warned ($warns out of 3)"
						else
							text_id="error"
						fi
					;;
					"!kick "*|"!kick")
						kick_id=$restrict_id
						tg_method kick_member
						if [[ "$(jshon -Q -e ok -u <<< "$curl_result")" != "false" ]]; then
							unban_id=$kick_id
							tg_method unban_member
							if [[ "$(jshon -Q -e ok -u <<< "$curl_result")" != "false" ]]; then
								text_id="$restrict_fname kicked"
							else
								text_id="error"
							fi
						else
							text_id="error"
						fi
					;;
					"!ban "*|"!ban")
						kick_id=$restrict_id
						tg_method kick_member
						if [[ "$(jshon -Q -e ok <<< "$curl_result")" != "false" ]]; then
							text_id="$restrict_fname banned"
						else
							text_id="error"
						fi
					;;
				esac
			else
				text_id="bot is not admin"
			fi
			get_reply_id reply
			tg_method send_message
		fi
	;;
	"!autounpin")
		get_member_id=$user_id
		tg_method get_chat_member
		if [[ "$(jshon -Q -e result -e status -u <<< "$curl_result" | grep -w "creator\|administrator")" != "" ]]; then
			get_reply_id self
			if [[ "$(grep "^chan_unpin" "db/chats/$chat_id")" ]]; then
				sed -i '/^chan_unpin/d' "db/chats/$chat_id"
				text_id="autounpin disabled"
				tg_method send_message
			else
				printf '%s\n' "chan_unpin" >> "db/chats/$chat_id"
				text_id="autounpin enabled"
				tg_method send_message
			fi
		fi
	;;
	"!exit")
		get_reply_id self
		if [[ $(is_admin) ]]; then
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
	
	## no prefix
	
	"respect+"|"respect+ "*|"+"|"-"|"+"[0-9]*|"-"[0-9]*|"+ "*|"- "*|"+"[0-9]*" "*|"-"[0-9]*" "*)
		get_reply_id self
		if [[ "${fn_arg[0]}" != "" ]]; then
			if [[ "$(grep -o "[^0-9]*" <<< "${fn_arg[0]}")" != "" ]]; then
				rep_id=$(grep '^id:' $(grep -rwi -- "$(sed 's/@//' <<< "${fn_arg[0]}")" db/users/ | cut -d : -f 1) | head -n 1 | sed 's/.*id: //')
			else
				if [[ -e db/users/"${fn_arg[0]}" ]]; then
					rep_id=${fn_arg[0]}
				fi
			fi
		elif [[ "$reply_to_user_id" != "" ]]; then
			if [[ "$reply_to_user_id" != "$user_id" ]]; then
				rep_id=$reply_to_user_id
			fi
		fi
		if [[ "$rep_id" != "$user_id" ]] && [[ "$rep_id" != "" ]]; then
			# check existing lock+
			[[ ! -d .lock+/respect/ ]] && mkdir -p .lock+/respect/
			if [[ "$lock_sticker" == "" ]]; then
				lockfile=.lock+/respect/"$user_id"-lock
				lock_time=$((60 + (RANDOM % 60)))
			else
				lockfile=.lock+/respect/"$user_id"-sticker-lock
				lock_time=$((60 + (RANDOM % 60) + lock_sticker))
			fi
			if [[ -e "$lockfile" ]]; then
				lock_age=$(bc <<< "$(date +%s) - $(stat -c "%W" $lockfile)")
			else
				lock_age="999999"
			fi
			if [[ $lock_age -ge $lock_time ]]; then
				rm -- "$lockfile"
				rep_fname=$(grep -w -- "^fname" db/users/"$rep_id" | sed 's/.*fname: //')
				rep_sign=$(grep -o "^." <<< "$(sed 's/^respect//' <<< "$normal_message")")
				rep_n=$(cut -f 1 -d ' ' <<< "$normal_message" | grep -o "[0-9]*")
				prevrep=$(grep "^totalrep" db/users/"$rep_id" | sed 's/^totalrep: //')
				if [[ "$prevrep" = "" ]]; then
					printf '%s\n' "totalrep: 0" >> db/users/"$rep_id"
					prevrep=0
				fi
				if [[ "$rep_n" == "" ]]; then
					sed -i "s/^totalrep: .*/totalrep: $(bc <<< "$prevrep $rep_sign 1")/" db/users/"$rep_id"
				elif [[ $(is_admin) ]] || [[ "$file_type" == "sticker" ]]; then
					sed -i "s/^totalrep: .*/totalrep: $(bc <<< "$prevrep $rep_sign $rep_n")/" db/users/"$rep_id"
				else
					return
				fi
				newrep=$(grep "^totalrep:" db/users/"$rep_id" | sed 's/^totalrep: //')
				prevrep_user=$(sed -n "s/^rep-$user_id: //p" db/users/"$rep_id")
				if [[ "$prevrep_user" = "" ]]; then
					printf '%s\n' "rep-$user_id: 0" >> db/users/"$rep_id"
					prevrep_user=0
				fi
				if [[ "$rep_n" == "" ]]; then
					sed -i "s/^rep-$user_id: .*/rep-$user_id: $(bc <<< "$prevrep_user $rep_sign 1")/" db/users/"$rep_id"
				elif [[ $(is_admin) ]] || [[ "$file_type" == "sticker" ]]; then
					sed -i "s/^rep-$user_id: .*/rep-$user_id: $(bc <<< "$prevrep_user $rep_sign $rep_n")/" db/users/"$rep_id"
				else
					return
				fi
				if [[ "$(grep respect <<< "$normal_message")" = "" ]]; then
					case "$rep_sign" in
						"+")
							text_id="respect + to $rep_fname ($newrep)"
							tg_method send_message
						;;
						"-")
							text_id="respect - to $rep_fname ($newrep)"
							tg_method send_message
					esac
				else
					voice_id="https://archneek.zapto.org/webaudio/respect.ogg"
					caption="respect + to $rep_fname ($newrep)"
					tg_method send_voice
				fi
				# create lock+
				[[ ! -e $lockfile ]] && touch -- "$lockfile"
			fi
		fi
	;;
	*)
		if [[ "$(grep -r -- "$bot_chat_user_id" "$bot_chat_dir")" != "" ]]; then
			bc_users=$(grep -r -- "$bot_chat_user_id" "$bot_chat_dir" | sed 's/.*:\s//' | tr ' ' '\n' | grep -v -- "$bot_chat_user_id")
			if [[ "$bc_users" != "" ]]; then
				bc_users_num=$(wc -l <<< "$bc_users")
				if [[ "$file_type" = "text" ]] && [[ "$reply_to_text" != "" ]]; then
					quote_reply=$(sed -n 1p <<< "$reply_to_text" | grep '^|')
					if [[ "$quote_reply" != "" ]]; then
						reply_to_text=$(sed '1,2d' <<< "$reply_to_text")
					fi
					if [[ "$(wc -c <<< "$reply_to_text")" -gt 30 ]]; then
						quote="$(head -c 30 <<< "$reply_to_text" | sed 's/^/| /g')..."
					else
						quote="$(head -c 30 <<< "$reply_to_text" | sed 's/^/| /g')"
					fi
					text_id=$(printf '%s\n' "$quote" "" "$normal_message")
					for c in $(seq "$bc_users_num"); do
						chat_id=$(sed -n ${c}p <<< "$bc_users")
						tg_method send_message &
					done
					wait
				else
					from_chat_id=$chat_id
					copy_id=$message_id
					for c in $(seq "$bc_users_num"); do
						chat_id=$(sed -n ${c}p <<< "$bc_users")
						tg_method copy_message &
					done
					wait
				fi
			fi
		fi
	;;
esac
case "$file_type" in
	"new_members")
		voice_id="https://archneek.zapto.org/webaudio/fanfare.ogg"
		get_reply_id self
		tg_method send_voice
	;;
esac
