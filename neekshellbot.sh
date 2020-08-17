#!/bin/bash
set -a
TOKEN=$(cat ./token)
TELEAPI="https://api.telegram.org/bot${TOKEN}"
exec 1>>neekshellbot.log
exec 2>>neekshellbot-errors.log
function jshon_n() {
	jshon "$@" 2>/dev/null
}
function inline_article() {
    cat <<EOF
    [{
        "type":"article",
        "id":"$RANDOM",
        "title":"$title",
        "input_message_content": {
            "message_text":"$message_text",
            "parse_mode":"html"
        }$description
    }]
EOF
}
function inline_joinchat() {
    for x in $(seq "$(ls -1 $bot_chat_dir | wc -l)"); do
        title=$(ls -1 $bot_chat_dir | sed -n "${x}"p)
        obj[$x]="{
        \"type\":\"article\",
        \"id\":\"$RANDOM\",
        \"title\":\"${title}\",
        \"reply_markup\":{\"inline_keyboard\":[[{\"text\":\"${title}\",\"url\":\"http://t.me/neekshellbot?start=joinchat${title}\"}]]},
        \"input_message_content\":{\"message_text\":\"join ${title}\"}
        },"
    done
    cat <<EOF
    [ $(echo ${obj[@]} | sed -E 's/(.*)},/\1}/') ]
EOF
}
function inline_keyboard_buttons() {
	for j in $(seq "$num_bot_chat"); do
		button_text[$j]=$(sed -n "${j}"p <<< "$list_bot_chat")
		obj[$j]="[{\"text\":\"${button_text[$j]}\",\"callback_data\":\"${button_text[$j]}\"}],"
	done
	cat <<EOF
	{
		"inline_keyboard": [
				$(sed -E 's/(.*)],/\1]/' <<< ${obj[@]})
		]
	}
EOF
}
function inline_booru() {
    for rig in $(seq "$picnumber"); do
        pic=$(echo "$piclist" | tr " " "\n" | sed -n "${rig}p")
        thumb=$(echo "$thumblist" | tr " " "\n" | sed -n "${rig}p")
        file=$(echo "$filelist" | tr " " "\n" | sed -n "${rig}p")
        obj[$rig]="{
        \"type\":\"photo\",
        \"id\":\"$RANDOM\",
        \"photo_url\":\"${pic}\",
        \"thumb_url\":\"${thumb}\",
        \"caption\":\"tag: ${tags}\\nsource: ${file}\"
        },"
    done
    cat <<EOF
    [ $(echo ${obj[@]} | sed -E 's/(.*)},/\1}/') ]
EOF
}
function inline_boorugif() {
    for rig in $(seq "$gifnumber"); do
        gif=$(echo "$giflist" | tr " " "\n" | sed -n "${rig}p")
        file=$(echo "$filelist" | tr " " "\n" | sed -n "${rig}p")
        obj[$rig]="{
        \"type\":\"gif\",
        \"id\":\"$RANDOM\",
        \"gif_url\":\"${gif}\",
        \"thumb_url\":\"${gif}\",
        \"caption\":\"tag: ${tags}\\nsource: ${file}\"
        },"
    done
    cat <<EOF
    [ $(echo ${obj[@]} | sed -E 's/(.*)},/\1}/') ]
EOF
}
function inline_searx() {
    for x in $(seq 0 $(($(jshon_n -e results -l <<< "$searx_results")-1))); do
        title=$(jshon_n -e results -e "$x" -e title -u <<< "$searx_results" | sed 's/"/\\"/g')
        url=$(jshon_n -e results -e "$x" -e url -u <<< "$searx_results" | sed 's/"/\\"/g')
        description=$(jshon_n -e results -e "$x" -e content -u <<< "$searx_results" | sed 's/"/\\"/g')
        obj[$x]="{
        \"type\":\"article\",
        \"id\":\"$RANDOM\",
        \"title\":\"${title}\",
        \"input_message_content\":{\"message_text\":\"${title}\n${url}\"},
        \"description\":\"${description}\"
        },"
    done
    cat <<EOF
    [ $(echo ${obj[@]} | sed -E 's/(.*)},/\1}/') ]
EOF
}
function send_message() {
	send_message_id=$(curl -s "${TELEAPI}/sendMessage" \
		--form-string "chat_id=$chat_id" \
		--form-string "parse_mode=html" \
		--form-string "reply_to_message_id=$reply_id" \
		--form-string "reply_markup=$markup_id" \
		--form-string "text=$text_id")
}
function send_photo() {
	curl -s "${TELEAPI}/sendPhoto" \
		-F "chat_id=$chat_id" \
		-F "parse_mode=html" \
		-F "reply_to_message_id=$reply_id" \
		-F "caption=$caption" \
		-F "photo=$photo_id" > /dev/null
}
function send_video() {
	curl -s "${TELEAPI}/sendVideo" \
		-F "chat_id=$chat_id" \
		-F "parse_mode=html" \
		-F "reply_to_message_id=$reply_id" \
		-F "caption=$caption" \
		-F "video=$video_id" > /dev/null
}
function send_audio() {
	curl -s "${TELEAPI}/sendAudio" \
		-F "chat_id=$chat_id" \
		-F "parse_mode=html" \
		-F "reply_to_message_id=$reply_id" \
		-F "caption=$caption" \
		-F "audio=$audio_id" > /dev/null
}
function send_voice() {
	curl -s "${TELEAPI}/sendVoice" \
		-F "chat_id=$chat_id" \
		-F "parse_mode=html" \
		-F "reply_to_message_id=$reply_id" \
		-F "caption=$caption" \
		-F "voice=$voice_id" > /dev/null
}
function send_animation() {
	curl -s "${TELEAPI}/sendAnimation" \
		-F "chat_id=$chat_id" \
		-F "parse_mode=html" \
		-F "reply_to_message_id=$reply_id" \
		-F "caption=$caption" \
		-F "animation=$animation_id" > /dev/null
}
function send_sticker() {
	curl -s "${TELEAPI}/sendSticker" \
		-F "chat_id=$chat_id" \
		-F "parse_mode=html" \
		-F "reply_to_message_id=$reply_id" \
		-F "caption=$caption" \
		-F "sticker=$sticker_id" > /dev/null
}
function send_document() {
	curl -s "${TELEAPI}/sendDocument" \
		-F "chat_id=$chat_id" \
		-F "parse_mode=html" \
		-F "reply_to_message_id=$reply_id" \
		-F "caption=$caption" \
		-F "document=$document_id" > /dev/null
}
function send_inline() {
	curl -s "${TELEAPI}/answerInlineQuery" \
		--form-string "inline_query_id=$inline_id" \
		--form-string "results=$return_query" \
		--form-string "next_offset=$offset" \
		--form-string "cache_time=100" \
		--form-string "is_personal=true"
}
function forward_message() {
	curl -s "${TELEAPI}/forwardMessage" \
		--form-string "chat_id=$to_chat_id" \
		--form-string "from_chat_id=$chat_id" \
		--form-string "message_id=$forward_id" > /dev/null
}
function inline_reply() {
	curl -s "${TELEAPI}/answerInlineQuery" \
		--form-string "inline_query_id=$inline_id" \
		--form-string "results=$return_query" \
		--form-string "next_offset=$offset" \
		--form-string "cache_time=100" \
		--form-string "is_personal=true" > /dev/null
}
function button_reply() {
	curl -s "${TELEAPI}/answerCallbackQuery" \
		--form-string "callback_query_id=$callback_id" \
		--form-string "text=$button_text_reply" > /dev/null
}
function send_processing() {
	processing_id=$(curl -s "${TELEAPI}/sendMessage" \
		--form-string "chat_id=$chat_id" \
		--form-string "text=processing..." | jshon_n -e result -e message_id -u)
}
function edit_message() {
	edited_id=$(curl -s "${TELEAPI}/editMessageText" \
		--form-string "chat_id=$chat_id" \
		--form-string "message_id=$to_edit_id" \
		--form-string "text=$edit_text" | jshon_n -e result -e message_id -u)
}
function delete_message() {
	curl -s "${TELEAPI}/deleteMessage" \
		--form-string "chat_id=$chat_id" \
		--form-string "message_id=$to_delete_id"
}
function get_normal_reply() {
	if [ "${pf}" = "" ]; then
		case $first_normal in	
			"+")
				if [ "$username_id" != "$reply_to_user_id" ]; then
					prevrep=$(sed -n 5p neekshell_db/users/"$reply_to_user_id" | sed 's/rep: //')
					[ "$prevrep" = "" ] && echo "rep: 0" >> neekshell_db/users/"$reply_to_user_id" && prevrep=$(sed -n 5p neekshell_db/users/"$reply_to_user_id" | sed 's/rep: //')
					sed -i "s/rep: ./rep: $((prevrep+1))/" neekshell_db/users/"$reply_to_user_id"
					newrep=$(sed -n 5p neekshell_db/users/"$reply_to_user_id" | sed 's/rep: //')
					voice_id="https://archneek.zapto.org/webaudio/respect.ogg"
					reply_id=$reply_to_id
					caption="respect + to $reply_to_user_fname ($newrep)"
					send_voice
				fi
				return
			;;
			*)
			if [ "$(grep -r -- "$bot_chat_user_id" "$bot_chat_dir")" != "" ]; then
				text_id=$first_normal photo_id=$first_normal animation_id=$first_normal video_id=$first_normal sticker_id=$first_normal audio_id=$first_normal voice_id=$first_normal document_id=$first_normal
				bc_users=$(grep -r -- "$bot_chat_user_id" $bot_chat_dir | sed 's/.*:\s//' | tr ' ' '\n' | grep -v -- "$bot_chat_user_id")
				bc_users_num=$(wc -l <<< "$bc_users")
				case $input_type in
					text)
					for c in $(seq "$bc_users_num"); do
						chat_id=$(sed -n "${c}"p <<< "$bc_users")
						send_message
						if [ "$(jshon_n -e description -u <<< "$send_message_id")" = "Forbidden: bot was blocked by the user" ]; then
							sed -i "s/$chat_id //" "$(grep -r -- "$bot_chat_user_id" $bot_chat_dir | cut -d : -f 1)"
						fi
					done
					return
					;;
					photo)
					for c in $(seq "$bc_users_num"); do
						chat_id=$(sed -n "${c}"p <<< "$bc_users")
						send_photo
					done
					return
					;;
					animation)
					for c in $(seq "$bc_users_num"); do
						chat_id=$(sed -n "${c}"p <<< "$bc_users")
						send_animation
					done
					return
					;;
					video)
					for c in $(seq "$bc_users_num"); do
						chat_id=$(sed -n "${c}"p <<< "$bc_users")
						send_video
					done
					return
					;;
					sticker)
					for c in $(seq "$bc_users_num"); do
						chat_id=$(sed -n "${c}"p <<< "$bc_users")
						send_sticker
					done
					return
					;;
					audio)
					for c in $(seq "$bc_users_num"); do
						chat_id=$(sed -n "${c}"p <<< "$bc_users")
						send_audio
					done
					return
					;;
					voice)
					for c in $(seq "$bc_users_num"); do
						chat_id=$(sed -n "${c}"p <<< "$bc_users")
						send_voice
					done
					return
					;;
					document)
					for c in $(seq "$bc_users_num"); do
						chat_id=$(sed -n "${c}"p <<< "$bc_users")
						send_document
					done
					return
					;;
				esac
			elif [ "$type" = "private" ]; then
				number=$(( ( RANDOM % 500 )  + 1 ))
				if		[ $number = 69 ]; then
					text_id="Nice."
				elif	[ $number = 1 ]; then
					text_id="We are number one"
				else
					text_id="$(
						echo "Things that happen
						Oh well
						Ok
						Alright
						Damn
						Bruh" | sort -R | head -n 1)"
				fi
				send_message
			fi
			return
			;;
		esac
	else
		case $first_normal in
			"${pf}start")
				text_id=$(echo -e "gitlab source: https://gitlab.com/craftmallus/neekshell-telegrambot\nrunning script: https://archneek.zapto.org/public-neekshell (symlinked)\nuse /neekshellzip to receive a zip file from source")
				reply_id=$message_id
				send_message
				return
			;;
			"${pf}start joinchat"*)
				admin=$(grep -v "#" neekshelladmins | grep -w "$username_id")
				if [ "$(grep -r -- "$bot_chat_user_id" "$bot_chat_dir")" = "" ] && [ "$admin" != "" ] ; then
					bot_chat_id=$(sed -e 's/[/!]start joinchat//' <<< "$first_normal")
					sed -i "s/\(users: \)/\1$bot_chat_user_id /" "$bot_chat_dir$bot_chat_id"
					text_id="joined $bot_chat_id"
				else
					text_id="you're already in an existing chat"
				fi
				send_message
				return
			;;
			"${pf}top+")
				list_rep=$(grep -r "rep: " neekshell_db/users/ | cut -d : -f 1)
				for x in $(seq $(wc -l <<< "$list_rep")); do
					user_file[$x]=$(sed -n ${x}p <<< "$list_rep")
					user_rep[$x]=$(sed -e 1,2d "${user_file[$x]}" | sed -e 's/fname: //' -e 's/lname: //' -e 's/rep: //' | tr '\n' ' ' | sed -E "s|(.*)\s(.*)\s|\2 ☆ <b>\1</b>|")
				done
				if [ "${user_rep[*]}" = "" ]; then
					text_id="oops, respect not found"
				else
					text_id=$(sort -nr <<< "$(printf '%s\n' "${user_rep[@]}")" | head -n 5)
				fi
				send_message
				return
			;;
			"${pf}neekshellzip")
				zip neekshell-"$message_id".zip neekshellbot.sh commands README.md LICENSE neekshelladmins.example neekshellbot-webhook.php
				document_id="@neekshell-$message_id.zip" reply_id=$message_id
				send_document
				rm neekshell-"$message_id".zip
				return
			;;
			"${pf}help")
				text_id=$(sed -n '/normal/,/endnormal/ p' commands | sed -e '1d' -e '$d' ; echo -e "\nfor administrative commands use /admin, for inline use /inline and for bot chats use /chat (in private only)")
				reply_id=$message_id
				send_message
				return
			;;
			"${pf}admin")
				text_id=$(sed -n '/admin/,/endadmin/ p' commands | sed -e '1d' -e '$d')
				reply_id=$message_id
				send_message
				return
			;;
			"${pf}inline")
				text_id=$(sed -n '/inline/,/endinline/ p' commands | sed -e '1d' -e '$d')
				reply_id=$message_id
				send_message
				return
			;;
			"${pf}button "*)
				text_id=$(sed -e 's/[/!]button //' <<< "$first_normal")
				reply_id=$message_id
				markup_id=$(inline_keyboard_buttons)
				send_message
				return
			;;
			"${pf}jpg")
				photo_id=$(jshon_n -e reply_to_message -e photo -e 0 -e file_id -u <<< "$message")
				animation_id=$(jshon_n -e reply_to_message -e animation -e file_id -u <<< "$message")
				video_id=$(jshon_n -e reply_to_message -e video -e file_id -u <<< "$message")
				sticker_id=$(jshon_n -e reply_to_message -e sticker -e file_id -u <<< "$message")
				audio_id=$(jshon_n -e reply_to_message -e audio -e file_id -u <<< "$message")
				voice_id=$(jshon_n -e reply_to_message -e voice -e file_id -u <<< "$message")
				request_id=$(jshon_n -e message_id -u <<< "$message")
				reply_id=$reply_to_id
				if [ "$photo_id" != "" ]; then
					file_path=$(curl -s "${TELEAPI}/getFile" --form-string "file_id=$photo_id" | jshon_n -e result -e file_path -u)
					wget -O pic-"$request_id".jpg "https://api.telegram.org/file/bot$TOKEN/$file_path"
					magick pic-"$request_id".jpg -quality 15 pic-low-"$request_id".jpg
					
					photo_id="@pic-low-$request_id.jpg"
					send_photo
					
					rm pic-"$request_id".jpg pic-low-"$request_id".jpg
				elif [ "$animation_id" != "" ]; then
					file_path=$(curl -s "${TELEAPI}/getFile" --form-string "file_id=$animation_id" | jshon_n -e result -e file_path -u)
					wget -O animation-"$request_id".mp4 "https://api.telegram.org/file/bot$TOKEN/$file_path"
					send_processing
					ffmpeg -i animation-"$request_id".mp4 -crf 48 -an animation-low-"$request_id".mp4
					to_edit_id=$processing_id edit_text="sending..." ; edit_message
					
					animation_id="@animation-low-$request_id.mp4"
					send_animation
					
					to_delete_id=$edited_id ; delete_message
					rm animation-"$request_id".mp4 animation-low-"$request_id".mp4
				elif [ "$video_id" != "" ]; then
					file_path=$(curl -s "${TELEAPI}/getFile" --form-string "file_id=$video_id" | jshon_n -e result -e file_path -u)
					wget -O video-"$request_id".mp4 "https://api.telegram.org/file/bot$TOKEN/$file_path"
					send_processing
					ffmpeg -i video-"$request_id".mp4 -crf 48 video-low-"$request_id".mp4
					to_edit_id=$processing_id edit_text="sending..." ; edit_message
					
					video_id="@video-low-$request_id.mp4"
					send_video
					
					to_delete_id=$edited_id ; delete_message
					rm video-"$request_id".mp4 video-low-"$request_id".mp4
				elif [ "$sticker_id" != "" ]; then
					file_path=$(curl -s "${TELEAPI}/getFile" --form-string "file_id=$sticker_id" | jshon_n -e result -e file_path -u)
					wget -O sticker-"$request_id".webp "https://api.telegram.org/file/bot$TOKEN/$file_path"
					convert sticker-"$request_id".webp sticker-"$request_id".jpg
					magick sticker-"$request_id".jpg -quality 1 sticker-low-"$request_id".jpg
					convert sticker-low-"$request_id".jpg sticker-low-"$request_id".webp
					
					sticker_id="@sticker-low-$request_id.webp"
					send_sticker
					
					rm sticker-"$request_id".webp sticker-"$request_id".jpg sticker-low-"$request_id".jpg sticker-low-"$request_id".webp
				elif [ "$audio_id" != "" ]; then
					file_path=$(curl -s "${TELEAPI}/getFile" --form-string "file_id=$audio_id" | jshon_n -e result -e file_path -u)
					wget -O audio-"$request_id".mp3 "https://api.telegram.org/file/bot$TOKEN/$file_path"
					send_processing
					ffmpeg -i audio-"$request_id".mp3 -vn -acodec libmp3lame -b:a 6k audio-low-"$request_id".mp3
					to_edit_id=$processing_id edit_text="sending..." ; edit_message
					
					audio_id="@audio-low-$request_id.mp3"
					send_audio
					
					to_delete_id=$edited_id ; delete_message
					rm audio-"$request_id".mp3 audio-low-"$request_id".mp3
				elif [ "$voice_id" != "" ]; then
					file_path=$(curl -s "${TELEAPI}/getFile" --form-string "file_id=$voice_id" | jshon_n -e result -e file_path -u)
					wget -O voice-"$request_id".ogg "https://api.telegram.org/file/bot$TOKEN/$file_path"
					send_processing
					ffmpeg -i voice-"$request_id".ogg -vn -acodec opus -b:a 6k -strict -2 voice-low-"$request_id".ogg
					to_edit_id=$processing_id edit_text="sending..." ; edit_message
					
					voice_id="@voice-low-$request_id.ogg"
					send_voice
					
					to_delete_id=$edited_id ; delete_message
					rm voice-"$request_id".ogg voice-low-"$request_id".ogg
				fi
				return
			;;
			"${pf}nfry")
				video_id=$(jshon_n -e reply_to_message -e video -e file_id -u <<< "$message")
				animation_id=$(jshon_n -e reply_to_message -e animation -e file_id -u <<< "$message")
				request_id=$(jshon_n -e message_id -u <<< "$message")
				if [ "$video_id" != "" ]; then
					file_path=$(curl -s "${TELEAPI}/getFile" --form-string "file_id=$video_id" | jshon_n -e result -e file_path -u)
					wget -O video-"$request_id".mp4 "https://api.telegram.org/file/bot$TOKEN/$file_path"
					send_processing
					ffmpeg -i video-"$request_id".mp4 -vf elbg=l=8,eq=saturation=3.0,noise=alls=20:allf=t+u video-fry-"$request_id".mp4
					to_edit_id=$processing_id edit_text="sending..." ; edit_message
					
					video_id="@video-fry-$request_id.mp4"
					send_video
					
					to_delete_id=$edited_id ; delete_message
					rm video-"$request_id".mp4 video-fry-"$request_id".mp4
				elif [ "$animation_id" != "" ]; then
					file_path=$(curl -s "${TELEAPI}/getFile" --form-string "file_id=$animation_id" | jshon_n -e result -e file_path -u)
					wget -O animation-"$request_id".mp4 "https://api.telegram.org/file/bot$TOKEN/$file_path"
					send_processing
					ffmpeg -i animation-"$request_id".mp4 -vf elbg=l=8,eq=saturation=3.0,noise=alls=20:allf=t+u -an animation-fry-"$request_id".mp4
					to_edit_id=$processing_id edit_text="sending..." ; edit_message
					
					animation_id="@animation-fry-$request_id.mp4"
					send_animation
					
					to_delete_id=$edited_id ; delete_message
					rm animation-"$request_id".mp4 animation-fry-"$request_id".mp4
				fi
			;;
			"${pf}wide")
				video_id=$(jshon_n -e reply_to_message -e video -e file_id -u <<< "$message")
				request_id=$(jshon_n -e message_id -u <<< "$message")
				if [ "$(jshon_n -e reply_to_message -e video -e duration -u <<< "$message")" -gt 60 ]; then
					text_id="max video duration: 1 minute"
					reply_id=$message_id
					send_message
					return
				fi
				if [ "$video_id" != "" ]; then
					file_path=$(curl -s "${TELEAPI}/getFile" --form-string "file_id=$video_id" | jshon_n -e result -e file_path -u)
					wget -O notwide-"$request_id".mp4 "https://api.telegram.org/file/bot$TOKEN/$file_path"
					duration=$(ffprobe notwide-"$request_id".mp4 2>&1 | grep Duration | sed 's/:/,/' | cut -d , -f 2 | sed 's/\..*//')
					if [ "$(cut -d : -f 1 <<< "$duration")" != "00" ]; then
						duration=$(cut -d : -f 1,2,3 <<< "$duration")
					elif [ "$(cut -d : -f 2 <<< "$duration")" != "00" ]; then
						duration=$(cut -d : -f 2,3 <<< "$duration")
					elif [ "$(cut -d : -f 3 <<< "$duration")" != "00" ]; then
						duration=$(cut -d : -f 3 <<< "$duration")
					fi
					ffmpeg -i notwide-"$request_id".mp4 -aspect 4:1 -c:v copy -an wide-"$request_id".mp4
					ffmpeg -ss 00 -t "$duration" -i wide-"$request_id".mp4 -ss 00 -t "$duration" -i ../webaudio/fantasia.aac -c:v copy -c:a aac wide-fantasia-"$request_id".mp4
					
					video_id="@wide-fantasia-$request_id.mp4"
					send_video
					
					rm notwide-"$request_id".mp4 wide-"$request_id".mp4 wide-fantasia-"$request_id".mp4
				fi
			;;
			"${pf}d$normaldice")
				chars=$(( $(wc -m <<< "$normaldice") - 1 ))
				text_id="<code>$(( ($(cat /dev/urandom | tr -dc '[:digit:]' | head -c $chars) % $normaldice) + 1 ))</code>"
				reply_id=$message_id
				send_message
				return
			;;
			"${pf}d$normaldice*$mul")
				for x in $(seq "$mul"); do
					chars=$(( $(wc -m <<< "$normaldice") - 1 ))
					result[$x]=$(( ($(cat /dev/urandom | tr -dc '[:digit:]' | head -c $chars) % $normaldice) + 1 ))
				done
				text_id="<code>${result[*]}</code>"
				reply_id=$message_id
				send_message
				return
			;;
			"${pf}hf")
				randweb=$(( ( RANDOM % 3 ) ))
				case $randweb in
				0)
					hflist=$(curl -s "https://www.hentai-foundry.com/pictures/random/?enterAgree=1" -c hfcookie/c | grep -io '<div class="thumbTitle"><a href=['"'"'"][^"'"'"']*['"'"'"]' | sed -e 's/^<div class="thumbTitle"><a href=["'"'"']//i' -e 's/["'"'"']$//i')
					counth=$(echo "$hflist" | grep -c "\n")
					randh=$(sed -n "$(( ( RANDOM % counth ) + 1 ))p" <<< "$hflist")
					
					photo_id=$(curl --cookie hfcookie/c -s https://www.hentai-foundry.com"$randh" | sed -n 's/.*src="\([^"]*\)".*/\1/p' | grep "pictures.hentai" | sed "s/^/https:/")
					caption="https://www.hentai-foundry.com$randh"
					reply_id=$message_id
					send_photo
					
					return
				;;
				1)
					randh=$(wget -q -O- 'https://rule34.xxx/index.php?page=post&s=random')
					
					photo_id=$(grep 'content="https://img.rule34.xxx' <<< "$randh" | sed -En 's/.*content="(.*)"\s.*/\1/p')
					caption="https://rule34.xxx/index.php?page=post&s=view&$(grep 'action="index.php?' <<< "$randh" | sed -En 's/.*(id=.*)&.*/\1/p')"
					reply_id=$message_id
					send_photo
					
					return
				;;
				2)
					randh=$(wget -q -O- 'https://safebooru.org/index.php?page=post&s=random')
					
					photo_id=$(grep 'content="https://safebooru.org' <<< "$randh" | sed -En 's/.*content="(.*)"\s.*/\1/p')
					caption="https://safebooru.org/index.php?page=post&s=view&$(grep 'action="index.php?' <<< "$randh" | sed -En 's/.*(id=.*)&.*/\1/p')"
					reply_id=$message_id
					send_photo
					
					return
				;;
				esac
				return
			;;
			"${pf}w$trad "*)
				search=$(sed -e "s/[/!]w$trad //" -e 's/\s/%20/g' <<< "$first_normal")
				wordreference=$(curl -A 'neekshellbot/1.0' -s "https://www.wordreference.com/$trad/$search" | sed -En "s/.*\s>(.*\s)<em.*/\1/p" | sed -e "s/<a.*//g" -e "s/<span.*'\(.*\)'.*/\1/g" | head | awk '!x[$0]++')
				reply_id=$message_id
				if [ "$wordreference" != "" ]; then
					text_id=$(echo -e "translations:\n$wordreference")
				else
					text_id="$(echo "$search" | sed 's/%20/ /g') not found"
				fi
				send_message
				return
			;;
			"${pf}setadmin "*)
				admin=$(grep -v "#" neekshelladmins | grep -w "$username_id")
				reply_id=$message_id
				if [ "$admin" != "" ]; then
					username=$(sed -e 's/[/!]setadmin @//' <<< "$first_normal")
					setadmin_id=$(cat "$(grep -r -- "$username" neekshell_db/users/ | cut -d : -f 1)" | sed -n 2p | sed 's/id: //')
					admin_check=$(grep -v "#" neekshelladmins | grep -w "$setadmin_id")
					if [ -z "$setadmin_id" ]; then
						text_id="user not found"
					elif [ "$admin_check" != "" ]; then
						text_id="$username already admin"
					else
						echo -e "# $username\n$setadmin_id" >> neekshelladmins
						text_id="admin $username set!"
					fi
				else
					text_id="<code>Access denied</code>"
				fi
				send_message
				return
			;;
			"${pf}deladmin "*)
				admin=$(grep -v "#" neekshelladmins | grep -w "$username_id")
				reply_id=$message_id
				if [ "$admin" != "" ]; then
					username=$(sed -e 's/[/!]deladmin @//' <<< "$first_normal")
					deladmin_id=$(cat "$(grep -r -- "$username" neekshell_db/users/ | cut -d : -f 1)" | sed -n 2p | sed 's/id: //')
					admin_check=$(grep -v "#" neekshelladmins | grep -w "$deladmin_id")
					if [ -z "$deladmin_id" ]; then
						text_id="user not found"
					elif [ "x$admin_check" != "x" ]; then
						sed -i "/$username/d" neekshelladmins
						sed -i "/$deladmin_id/d" neekshelladmins
						text_id="$username is no longer admin"
					else
						echo "$username is not admin"
					fi
				else
					text_id="<code>Access denied</code>"
				fi
				send_message
				return
			;;
			"${pf}bin "*)
				admin=$(grep -v "#" neekshelladmins | grep -w "$username_id")
				reply_id=$message_id
				if [ "$admin" != "" ]; then
					command=$(sed 's/[/!]bin //' <<< "$first_normal")
					text_id=$(bash -c "$command" 2>&1)
					text_id="<code>$(sed 's/[<]/\&lt;/g' <<< "$text_id")</code>"
				else
					text_id="<code>Access denied</code>"
				fi
				send_message
				return
			;;
			"${pf}cpustat")
				text_id=$(cpu_perc=$(awk -v a="$(awk '/cpu /{print $2+$4,$2+$4+$5}' /proc/stat; sleep 1)" '/cpu /{split(a,b," "); print 100*($2+$4-b[1])/($2+$4+$5-b[2])}' /proc/stat)
					if [ "$cpu_perc" != "100" ]; then 
						sed -E 's/(.*)\..*/\1%/' <<< "$cpu_perc"
					else
						sed 's/$/%/' <<< "$cpu_perc"
					fi)
				reply_id=$message_id
				send_message
			;;
			"${pf}broadcast "*|"${pf}broadcast")
				admin=$(grep -v "#" neekshelladmins | grep -w "$username_id")
				if [ "$admin" != "" ]; then
					listchats=$(grep -rnw neekshell_db/chats/ -e 'supergroup' | cut -d ':' -f 1)
					numchats=$(wc -l <<< "$listchats")
					text_id=$(sed "s/[!/]broadcast//" <<< "$first_normal")
					if [ "$text_id" != "" ]; then
						for x in $(seq "$numchats"); do
							brid[$x]=$(sed -n 2p "$(sed -n "${x}"p <<< "$listchats")" | sed 's/id: //')
							chat_id=${brid[$x]}
							send_message
							sleep 2
						done
					elif [ "$reply_to_id" != "" ]; then
						text_id=$(jshon_n -e reply_to_message -e text -u <<< "$message")
						photo_id=$(jshon_n -e reply_to_message -e photo -e 0 -e file_id -u <<< "$message")
						animation_id=$(jshon_n -e reply_to_message -e animation -e file_id -u <<< "$message")
						video_id=$(jshon_n -e reply_to_message -e video -e file_id -u <<< "$message")
						sticker_id=$(jshon_n -e reply_to_message -e sticker -e file_id -u <<< "$message")
						audio_id=$(jshon_n -e reply_to_message -e audio -e file_id -u <<< "$message")
						voice_id=$(jshon_n -e reply_to_message -e voice -e file_id -u <<< "$message")
						for x in $(seq "$numchats"); do
							brid[$x]=$(sed -n 2p "$(sed -n "${x}"p <<< "$listchats")" | sed 's/id: //')
							chat_id=${brid[$x]}
							[ "$text_id" != "" ] && send_message
							[ "$photo_id" != "" ] && send_photo
							[ "$animation_id" != "" ] && send_animation
							[ "$video_id" != "" ] && send_video
							[ "$sticker_id" != "" ] && send_sticker
							[ "$audio_id" != "" ] && send_audio
							[ "$voice_id" != "" ] && send_voice
							sleep 2
						done
					else
						text_id="Write something after broadcast command or reply to forward"
						send_message
					fi
					return
				else
					text_id="<code>Access denied</code>"
				fi
				return
			;;
			"${pf}fortune")
				text_id=$(/usr/bin/fortune fortunes paradoxum goedel linuxcookie | tr '\n' ' ' | awk '{$2=$2};1')
				reply_id=$message_id
				send_message
				return
			;;
			"${pf}owoifer"|"${pf}cringe")
				reply=$(jshon_n -e reply_to_message -e text -u <<< "$message")
				if [ "$reply" != "" ]; then
					[ "$first_normal" = "${pf}cringe" ] && owoarray=(" 🥵 " " 🙈 " " 🤣 " " 😘 " " 🥺 " " 💁‍♀️ " " OwO " " 😳 " " 🤠 " " 🤪 " " 😜 " " 🤬 " " 🤧 " " 🦹‍♂ ") || owoarray=(" owo " " ewe " " uwu ")
					numberspace=$(tr -dc ' ' <<< "$reply" | wc -c)
					
					for x in $(seq $((numberspace / 8))); do
						reply=$(sed "s/\s/\n/$(((RANDOM % numberspace)+1))" <<< "$reply")
					done
					
					fixed_text=$(
						for x in $(seq $(($(wc -l <<< "$reply") - 1))); do 
							fixed_part[$x]=$(sed -n "${x}"p <<< "$reply" | sed "s/$/ ${owoarray[$((RANDOM % ${#owoarray[@]}))]}/")
						done
						echo "${fixed_part[*]}" "$(tail -1 <<< "$reply")")
					
					text_id=$(sed -e 's/[lr]/w/g' -e 's/[LR]/W/g' <<< "$fixed_text")
					reply_id=$reply_to_id
				else
					text_id="reply to a text message"
					reply_id=$message_id
				fi
				send_message
				return
			;;
			"${pf}sed "*)
				reply=$(jshon_n -e reply_to_message -e text -u <<< "$message")
				if [ "$reply" != "" ]; then
					regex=$(sed -e 's/[/!]sed //' <<< "$first_normal")
					sed=$(sed -En "s/$regex/p" <<< "$reply")
					text_id=$(echo "<b>FTFY:</b>" ; echo "$sed")
					reply_id=$reply_to_id
				else
					text_id="reply to a text message"
					reply_id=$message_id
				fi
				send_message
				return
			;;
			"${pf}ping")
				text_id=$(echo "pong" ; ping -c 1 api.telegram.org | grep time= | sed -E "s/(.*time=)(.*)( ms)/\2ms/")
				reply_id=$message_id
				send_message
				return
			;;
			"${pf}bang")
				if [ "$type" != "private" ]; then
				admin=$(grep -v "#" neekshelladmins | grep -w "$username_id")
				reply_id=$reply_to_id
					if [ "$admin" != "" ]; then
						username=$(jshon_n -e reply_to_message -e from -e username -u <<< "$message")
						user_id=$(jshon_n -e reply_to_message -e from -e id -u <<< "$message")
						curl -s "${TELEAPI}/restrictChatMember" \
							--form-string "chat_id=$chat_id" \
							--form-string "user_id=$user_id" \
							--form-string "can_send_messages=false" \
							--form-string "until_date=32477736097" > /dev/null
						
						sticker_id="https://archneek.zapto.org/webpics/vicious_dies2.webp"
						send_sticker
						
						text_id=$( [ "$username" != "" ] && echo "@$username (<a href=\"tg://user?id=$userid\">$userid</a>) terminato" || echo "<a href=\"tg://user?id=$userid\">$userid</a> terminato")
					else
						text_id="<code>Access denied</code>"
					fi
				send_message
				return
				fi
			;;
			"${pf}nomedia")
				if [ "$type" != "private" ]; then
				admin=$(grep -v "#" neekshelladmins | grep -w "$username_id")
				reply_id=$message_id
					if [ "$admin" != "" ]
					then
						if [ "$(curl -s "${TELEAPI}/getChat" --form-string "chat_id=$chat_id" | jshon_n -e result -e permissions -e can_send_media_messages -u)" = "true" ]; then
							set_chat_permissions=$(curl -s "${TELEAPI}/setChatPermissions" -d "{ \"chat_id\": \"$chat_id\", \"permissions\": { \"can_send_messages\": true, \"can_send_media_messages\": false, \"can_send_other_messages\": false, \"can_send_polls\": false, \"can_add_web_page_previews\": false } }" -H 'Content-Type: application/json' | jshon_n -e ok -u)
							if [ "$set_chat_permissions" = "true" ]; then
								text_id="no-media mode activated, send again to deactivate"
							else
								text_id="error: bot is not admin"
							fi
						else
							set_chat_permissions=$(curl -s "${TELEAPI}/setChatPermissions" -d "{ \"chat_id\": \"$chat_id\", \"permissions\": { \"can_send_messages\": true, \"can_send_media_messages\": true, \"can_send_other_messages\": true, \"can_send_polls\": true, \"can_add_web_page_previews\": true } }" -H 'Content-Type: application/json' | jshon_n -e ok -u)
							if [ "$set_chat_permissions" = "true" ]; then
								text_id="no-media mode deactivated"
							else
								text_id="error: bot is not admin"
							fi
						fi
					else
						text_id="<code>Access denied</code>"
					fi
					send_message
				fi
			;;
			"${pf}silence")
				if [ "$type" != "private" ]; then
				admin=$(grep -v "#" neekshelladmins | grep -w "$username_id")
				reply_id=$message_id
					if [ "$admin" != "" ]
					then
						if [ "$(curl -s "${TELEAPI}/getChat" --form-string "chat_id=$chat_id" | jshon_n -e result -e permissions -e can_send_messages -u)" = "true" ]; then
							set_chat_permissions=$(curl -s "${TELEAPI}/setChatPermissions" -d "{ \"chat_id\": \"$chat_id\", \"permissions\": { \"can_send_messages\": false, \"can_send_media_messages\": false, \"can_send_other_messages\": false, \"can_send_polls\": false, \"can_add_web_page_previews\": false } }" -H 'Content-Type: application/json' | jshon_n -e ok -u)
							if [ "$set_chat_permissions" = "true" ]; then
								text_id="read only mode activated, send again to deactivate"
							else
								text_id="error: bot is not admin"
							fi
						else
							set_chat_permissions=$(curl -s "${TELEAPI}/setChatPermissions" -d "{ \"chat_id\": \"$chat_id\", \"permissions\": { \"can_send_messages\": true, \"can_send_media_messages\": true, \"can_send_other_messages\": true, \"can_send_polls\": true, \"can_add_web_page_previews\": true } }" -H 'Content-Type: application/json' | jshon_n -e ok -u)
							if [ "$set_chat_permissions" = "true" ]; then
								text_id="read only mode deactivated"
							else
								text_id="error: bot is not admin"
							fi
						fi
						
					else
						text_id="<code>Access denied</code>"
					fi
					send_message
				fi
			;;
			"${pf}exit")
				admin=$(grep -v "#" neekshelladmins | grep -w "$username_id")
				reply_id=$message_id
				if [ "$admin" != "" ]; then
					text_id="goodbye"
					send_message
					curl -s "$TELEAPI/leaveChat" --form-string "chat_id=$chat_id" > /dev/null
				else
					text_id="<code>Access denied</code>"
					send_message
				fi
			;;
			"${pf}tag "*)
				username=$(sed -E 's/.* (\[.*\]) .*/\1/' <<< "$first_normal" | tr -d '[@]')
				usertext=$(sed -E 's/^.*\s.*\s(\(.*)/\1/' <<< "$first_normal" | tr -d '()')
				userid=$(cat "$(grep -r -- "$username" neekshell_db/users/ | cut -d : -f 1)" | sed -n 2p | sed 's/id: //')
				if [ "$userid" != "" ] && [ "$usertext" != "" ]; then
					text_id=$(echo -e "<a href=\"tg://user?id=$userid\">$usertext</a>")
				elif [ "$userid" = "" ]; then
					text_id="$username not found"
				fi
				send_message
				return
			;;
			"${pf}forward "*)
			if [ "$type" = "private" ]; then
				username=$(echo "$first_normal" | sed -e 's/[/!]forward @//')
				reply_id=$message_id
				if [ ! -e "$(find neekshell_db/users/ -iname "$username")" ]; then
					text_id="user not found"
					send_message
				else
					to_chat_id=$(cat "$(grep -r -- "$username" neekshell_db/users/ | cut -d : -f 1)" | sed -n 2p | sed 's/id: //')
					forward_id=$reply_to_id
					forward_message
				fi
			fi
			return
			;;
			"${pf}chat "*|"${pf}chat")
				admin=$(grep -v "#" neekshelladmins | grep -w "$username_id")
				if [ "$type" = "private" ] || [ "$admin" != "" ] ; then
					action=$(echo "$first_normal" | sed -e 's/[/!]chat //')
					reply_id=$message_id
					case $action in
						"create")
							[ ! -d $bot_chat_dir ] && mkdir -p $bot_chat_dir
							if [ "$(dir $bot_chat_dir | grep -o -- "$bot_chat_user_id")" = "" ]; then
								file_bot_chat="$bot_chat_dir$bot_chat_user_id"
								[ ! -e "$file_bot_chat" ] && echo "users: " > "$file_bot_chat"
								text_id="your chat id: \"$bot_chat_user_id\""
							else
								text_id="you've already an existing chat"
							fi
							send_message
						;;
						"delete")
							[ ! -d $bot_chat_dir ] && text_id="no existing chats" && send_message && return
							if [ "$(dir $bot_chat_dir | grep -o -- "$bot_chat_user_id")" != "" ]; then
								file_bot_chat="$bot_chat_dir$bot_chat_user_id"
								rm "$file_bot_chat"
								text_id="\"$bot_chat_user_id\" deleted"
							else
								text_id="you have not created any chat yet"
							fi
							send_message
						;;
						"join")
							if [ "$(grep -r -- "$bot_chat_user_id" "$bot_chat_dir")" = "" ] && [ "$type" = "private" ] ; then
								text_id="Select chat to join:"
								num_bot_chat=$(ls -1 $bot_chat_dir | wc -l)
								list_bot_chat=$(ls -1 $bot_chat_dir)
								markup_id=$(inline_keyboard_buttons)
							elif [ "$(grep -r -- "$bot_chat_user_id" "$bot_chat_dir")" = "" ] && [ "$type" != "private" ] ; then
								text_id="Attention: you're in a group, send !start joinchat[bot_chat_id] to join a group chat, e.g.: /start joinchat-1234567890. Use !chat list for a list of available group chats"
							else
								text_id="you're already in an existing chat"
							fi
							send_message
						;;
						"leave")
							if [ "$(grep -r -- "$bot_chat_user_id" "$bot_chat_dir")" != "" ]; then
								text_id="Select chat to leave:"
								num_bot_chat=$(ls -1 $bot_chat_dir | wc -l)
								list_bot_chat=$(ls -1 $bot_chat_dir)
								markup_id=$(inline_keyboard_buttons)
							else
								text_id="you are not in an any chat yet"
							fi
							send_message
						;;
						"users")
							if [ "$(grep -r -- "$bot_chat_user_id" "$bot_chat_dir")" != "" ]; then
								text_id="number of active users: $(grep -r -- "$bot_chat_user_id" $bot_chat_dir | sed 's/.*:\s//' | tr ' ' '\n' | sed '/^$/d' | wc -l)"
							else
								text_id="you are not in an any chat yet"
							fi
							send_message
						;;
						"list")
							text_id="$(
								for c in $(seq "$(ls -1 "$bot_chat_dir" | wc -l)"); do
									bot_chat_id=$(ls -1 "$bot_chat_dir" | sed -n "${c}"p)
									bot_chat_users=$(sed 's/.*:\s//' "$bot_chat_dir$bot_chat_id" | tr ' ' '\n' | sed '/^$/d' | wc -l)
									echo "chat: $bot_chat_id users: $bot_chat_users"
								done
							)"
							[ "$text_id" = "" ] && text_id="no chats found"
							send_message
						;;
						*)
							text_id=$(sed -n '/botchat/,/endbotchat/ p' commands | sed -e '1d' -e '$d')
							send_message
						;;
					esac
				fi
				return
			;;
			"${pf}neofetch")
				text_id=$(neofetch --stdout)
				text_id="<code>$(	echo '              ' "$(sed -n 1p <<< "$text_id")"
									echo '  .-----.     ' "$(sed -n 2p <<< "$text_id")"
									echo '.`    _  `.   ' "$(sed -n 3p <<< "$text_id")"
									echo '`.   (_)   `. ' "$(sed -n 4p <<< "$text_id")"
									echo '  `.        / ' "$(sed -n 5p <<< "$text_id")"
									echo ' .`       .`  ' "$(sed -n 6p <<< "$text_id")"
									echo '/       .`    ' "$(sed -n 8p <<< "$text_id")"
									echo '\____.-`      ' "$(sed -n 11p <<< "$text_id")"
									echo '              ' "$(sed -n 12p <<< "$text_id")")</code>"
				send_message
			;;
		esac
	fi
}
function get_inline_reply() {
	inlinedice=$(echo "$results" | tr -d '[:alpha:]')
	
	if [ "$(grep -w "gb\|gbgif" <<< "$results")" != "" ]; then
		booru="gelbooru.com"
		ilb="g"
	elif [ "$(grep -w "xb\|xbgif" <<< "$results")" != "" ]; then
		booru="xbooru.com"
		ilb="x"
	elif [ "$(grep -w "realb\|realbgif" <<< "$results")" != "" ]; then
		booru="realbooru.com"
		ilb="real"
	elif [ "$(grep -w "r34b\|r34bgif" <<< "$results")" != "" ]; then
		booru="rule34.xxx"
		ilb="r34"
	fi
	
	case $results in
		"help")
			title="Ok"
			message_text="Ok"
			description=",\"description\":\"Alright\""
			return_query=$(inline_article)
			send_inline
			return
		;;
		"joinchat")
			return_query=$(inline_joinchat)
			send_inline
			return
		;;
		"d$inlinedice")
			if [ "$inlinedice" != "" ]
				then
				title="Result of d$inlinedice"
				number=$(( ( RANDOM % inlinedice )  + 1 ))
				message_text=$(echo -e "Result of d$inlinedice\n: $number")
				return_query=$(inline_article)
				send_inline
			fi
			return
		;;
		*" bin")
			admin=$(grep -v "#" neekshelladmins | grep -w "$inline_user_id")
			if [ "$admin" != "" ]; then
				command=$(sed 's/ bin//' <<< "$results")
				title="$(echo "$~> ""$command""" ; bash -c "$command" 2>&1 )"
				message_text="<code>$title</code>"
				return_query=$(inline_article)
				send_inline
			fi
			return
		;;
		"tag "*)
			username=$(sed -Ee 's/(.* )(\[.*\]) ((.*))/\2/' -e 's/[[:punct:]]//g' <<< "$results")
			title=$(sed -Ee 's/(.* )(\[.*\]) ((.*))/\3/' -Ee 's/[[:punct:]](.*)[[:punct:]]/\1/' <<< "$results")
			userid=$(cat "$(grep -r -- "$username" neekshell_db/users/ | cut -d : -f 1)" | sed -n 2p | sed 's/id: //')
			message_text="<a href=\\\"tg://user?id=$userid\\\">$title</a>"
			description=",\"description\":\"$username\""
			return_query=$(inline_article)
			send_inline
			return
		;;
		'search '*)
			offset=$(($(jshon_n -e offset -u <<< "$inline")+1))
			search=$(sed 's/search //' <<< "$results" | sed 's/\s/%20/g')
			searx_results=$(curl -s "https://archneek.zapto.org/searx/?q=$search&pageno=$offset&categories=general&format=json")
			return_query=$(inline_searx)
			send_inline
			return
		;;
		"${ilb}b "*)
			offset=$(($(jshon_n -e offset -u <<< "$inline")+1))
			tags=$(sed "s/${ilb}b //" <<< "$results")
			getbooru=$(curl -A 'Mozilla/5.0' -s "https://$booru/index.php?page=dapi&s=post&pid=$offset&tags=$tags&q=index&limit=5")
			thumblist=$(sed -n 's/.*preview_url="\([^"]*\)".*/\1/p' <<< "$getbooru" | grep -E 'jpg|jpeg|png')
			piclist=$(sed -n 's/.*sample_url="\([^"]*\)".*/\1/p' <<< "$getbooru" | grep -E 'jpg|jpeg|png')
			filelist=$(sed -n 's/.*file_url="\([^"]*\)".*/\1/p' <<< "$getbooru" | grep -E 'jpg|jpeg|png')
			picnumber=$(sed -n 's/.*sample_url="\([^"]*\)".*/\1/p' <<< "$getbooru" | grep -E -c 'jpg|jpeg|png')
			return_query=$(inline_booru)
			send_inline
			return
		;;
		"${ilb}bgif "*)
			offset=$(($(jshon_n -e offset -u <<< "$inline")+1))
			tags=$(sed "s/${ilb}bgif //" <<< "$results")
			if [ "$ilb" != "g" ]; then
				getbooru=$(curl -A 'Mozilla/5.0' -s "https://$booru/index.php?page=dapi&s=post&pid=$offset&tags=gif+$tags&q=index&limit=20")
			else
				getbooru=$(curl -A 'Mozilla/5.0' -s "https://$booru/index.php?page=dapi&s=post&pid=$offset&tags=animated+$tags&q=index&limit=20")
			fi
			giflist=$(sed -n 's/.*sample_url="\([^"]*\)".*/\1/p' <<< "$getbooru" | grep -E 'gif')
			filelist=$(sed -n 's/.*file_url="\([^"]*\)".*/\1/p' <<< "$getbooru" | grep -E 'gif')
			gifnumber=$(sed -n 's/.*sample_url="\([^"]*\)".*/\1/p' <<< "$getbooru" | grep -E -c 'gif')
			return_query=$(inline_boorugif)
			send_inline
			return
		;;
		*)
			title="Ok"
			message_text="Ok"
			description=",\"description\":\"Alright\""
			return_query=$(inline_article)
			send_inline
			return
		;;
	esac
}
function get_button_reply() {
	case $callback_message_text in
		"Select chat to join:")
			chat_id=$callback_user_id
			if [ "$(grep -r "$callback_user_id" $bot_chat_dir)" = "" ]; then
				sed -i "s/\(users: \)/\1$callback_user_id /" $bot_chat_dir"$callback_data"
				button_text_reply="joined"
				text_id="joined $callback_data"
			else
				button_text_reply="you're already in an existing chat"
				text_id="you're already in an existing chat"
			fi
			button_reply
			send_message
			return
		;;
		"Select chat to leave:")
			sed -i "s/$callback_user_id //" $bot_chat_dir"$callback_data"
			button_text_reply="bye"
			button_reply
			chat_id=$callback_user_id
			text_id="$callback_data is no more"
			send_message
			return
		;;
		*)
			text_id="$callback_data"
			button_reply
			chat_id=$callback_user_id
			send_message
			return
		;;
	esac
}
function process_reply() {
	message=$(jshon_n -e message <<< "$input")
	
	# user database
	username_tag=$(jshon_n -e from -e username -u <<< "$message") username_id=$(jshon_n -e from -e id -u <<< "$message") username_fname=$(jshon_n -e from -e first_name -u <<< "$message") username_lname=$(jshon_n -e from -e last_name -u <<< "$message")
	if [ "$username_id" != "" ]; then
		[ ! -d neekshell_db/users/ ] && mkdir -p neekshell_db/users/
		file_user=neekshell_db/users/"$username_id"
		if [ ! -e "$file_user" ]; then
			[ "$username_tag" = "" ] && username_tag="(empty)"
			echo "tag: $username_tag" > "$file_reply_user"
			echo "id: $username_id" >> "$file_reply_user"
			echo "fname: $username_fname" >> "$file_reply_user"
			echo "lname: $username_lname" >> "$file_reply_user"
		fi
	fi
	reply_to_id=$(jshon_n -e reply_to_message -e message_id -u <<< "$message") reply_to_user_id=$(jshon_n -e reply_to_message -e from -e id -u <<< "$message") reply_to_user_tag=$(jshon_n -e reply_to_message -e from -e username -u <<< "$message") reply_to_user_fname=$(jshon_n -e reply_to_message -e from -e first_name -u <<< "$message") reply_to_user_lname=$(jshon_n -e reply_to_message -e from -e last_name -u <<< "$message")
	if [ "$reply_to_user_id" != "" ]; then
		[ ! -d neekshell_db/users/ ] && mkdir -p neekshell_db/users/
		file_reply_user=neekshell_db/users/"$reply_to_user_id"
		if [ ! -e "$file_reply_user" ]; then
			[ "$reply_to_user_tag" = "" ] && $reply_to_user_tag="(empty)"
			echo "tag: $reply_to_user_tag" > "$file_reply_user"
			echo "id: $reply_to_user_id" >> "$file_reply_user"
			echo "fname: $reply_to_user_fname" >> "$file_reply_user"
			echo "lname: $reply_to_user_lname" >> "$file_reply_user"
		fi
	fi
	# chat database
	chat_title=$(jshon_n -e chat -e title -u <<< "$message") chat_id=$(jshon -e chat -e id -u <<< "$message") type=$(jshon_n -e chat -e type -u <<< "$message")
	if [ "$chat_title" != "" ]; then
		[ ! -d neekshell_db/chats/ ] && mkdir -p neekshell_db/chats/
		file_chat="neekshell_db/chats/$chat_title"
		[ ! -e "$file_chat" ] && echo "title: $chat_title" > "$file_chat" && echo -e "id: $chat_id\ntype: $type" >> "$file_chat"
	fi
	if [ "$type" = "private" ]; then
		bot_chat_dir="neekshell_db/bot_chats/"
		bot_chat_user_id=$username_id
	else
		bot_chat_dir="neekshell_db/bot_group_chats/"
		bot_chat_user_id=$chat_id
	fi
	
	[ ! -e ./botinfo ] && touch ./botinfo && wget -q -O ./botinfo "${TELEAPI}/getMe"
	text=$(jshon_n -e text -u <<< "$message") photo_r=$(jshon_n -e photo -e 0 -e file_id -u <<< "$message") animation_r=$(jshon_n -e animation -e file_id -u <<< "$message") video_r=$(jshon_n -e video -e file_id -u <<< "$message") sticker_r=$(jshon_n -e sticker -e file_id -u <<< "$message") audio_r=$(jshon_n -e audio -e file_id -u <<< "$message") voice_r=$(jshon_n -e voice -e file_id -u <<< "$message") document_r=$(jshon_n -e document -e file_id -u <<< "$message")
	
	if [ "$text" != "" ]; then
		input_type="text"
	elif [ "$sticker_r" != "" ]; then
		input_type="sticker"
	elif [ "$animation_r" != "" ]; then
		input_type="animation"
	elif [ "$photo_r" != "" ]; then
		input_type="photo"
	elif [ "$video_r" != "" ]; then
		input_type="video"
	elif [ "$audio_r" != "" ]; then
		input_type="audio"
	elif [ "$voice_r" != "" ]; then
		input_type="voice"
	elif [ "$document_r" != "" ]; then
		input_type="document"
	fi
	
	pf=${text/[^\/\!]*/}
	message_id=$(jshon_n -e message_id -u <<< "$message")
	
	inline=$(jshon_n -e inline_query <<< "$input")
	inline_user=$(jshon_n -e from -e username -u <<< "$inline") inline_user_id=$(jshon_n -e from -e id -u <<< "$inline") inline_id=$(jshon_n -e id -u <<< "$inline") results=$(jshon_n -e query -u <<< "$inline")

	callback=$(jshon_n -e callback_query <<< "$input")
	callback_user=$(jshon_n -e from -e username -u <<< "$callback") callback_user_id=$(jshon_n -e from -e id -u <<< "$callback") callback_id=$(jshon_n -e id -u <<< "$callback") callback_data=$(jshon_n -e data -u <<< "$callback") callback_message_text=$(jshon_n -e message -e text -u <<< "$callback")
	
	first_normal=$(echo $photo_r $animation_r $video_r $sticker_r $audio_r $voice_r)
	if [ "$first_normal" = "" ]; then
		first_normal="$document_r"
		if [ "$first_normal" = "" ]; then
			first_normal="${text/@$(cat botinfo | jshon_n -e result -e username -u)/}"
		fi
	fi
	
	[ "${first_normal/*[^0-9]/}" != "" ] && normaldice=$(echo "$first_normal" | tr -d '/![:alpha:]' | sed 's/\*.*//g') mul=$(echo "$first_normal" | tr -d '/![:alpha:]' | sed 's/.*\*//g')
	trad=$(sed -e 's/[!/]w//' -e 's/\s.*//' <<< "$first_normal" | grep "enit\|iten")
	
	if [ "$first_normal" != "" ]; then
		get_normal_reply
	elif [ "$results" != "" ]; then
		get_inline_reply
	elif [ "$callback_data" != "" ]; then
		get_button_reply
	fi
	
#	if	[ "$first_normal" != "" ] && [ "$type" = "private" ] ; then
#		echo "normal=$first_normal" ; echo "from ${username_tag}, type = $input_type, at $(date "+%Y-%m-%d %H:%M")" ; echo "--"
#	elif [ "$results" != "" ]; then
#		echo "inline=${results}" ; echo "from ${inline_user} at $(date "+%Y-%m-%d %H:%M")" ; echo "--"
#	fi
}
input=$1
process_reply
