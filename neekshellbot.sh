#!/bin/mksh
START_TIME=$(bc <<< "$(date +%s%N) / 1000000")
PS4="[$(date "+%F %H:%M:%S")] "
exec 1>>"log.log" 2>&1
set -a
TOKEN=$(cat ./token)
TELEAPI="https://api.telegram.org/bot${TOKEN}"
jshon_n() {
	jshon "$@" 2>/dev/null
}
get_reply_id() {
	case $1 in
		any)
			if [ "$reply_to_message" != "" ]; then
				reply_id=$reply_to_id
			else
				reply_id=$message_id
			fi
		;;
		self)
			reply_id=$message_id
		;;
		reply)
			reply_id=$reply_to_id
		;;
	esac
}
is_admin() {
	grep -v "#" admins | grep -w "$username_id\|$inline_user_id"
}
loading() {
	case $1 in
		1)
			text_id="processing ..."
			processing_id=$(tg_method send_message | jshon_n -e result -e message_id -u)
		;;
		value)
			to_edit_id=$processing_id
			edit_text="$2"
			processing_id=$(tg_method edit_message | jshon_n -e result -e message_id -u)
		;;
		2)
			to_edit_id=$processing_id
			edit_text="sending..."
			edited_id=$(tg_method edit_message | jshon_n -e result -e message_id -u)
		;;
		3)
			to_delete_id=$edited_id
			tg_method delete_message > /dev/null
		;;
		error)
			to_delete_id=$processing_id
			tg_method delete_message > /dev/null
		;;
	esac
}
r_subreddit() {
	[ "$1" = "" ] && exit
	subreddit=$1
	sort=$2
	enable_markdown=true
	case $subreddit in
		none)
			case $sort in
				random)
					input=$(wget -q -O- "https://reddit.com/random/.json")
					hot=$(jshon -e 0 -e data -e children -e 0 -e data <<< "$input")
				;;
			esac
		;;
		*)
			case $sort in
				random)
					input=$(wget -q -O- "https://reddit.com/r/${subreddit}/random/.json")
					hot=$(jshon -e 0 -e data -e children -e 0 -e data <<< "$input")
				;;
				*)
					amount=5
					input=$(wget -q -O- "https://reddit.com/r/${subreddit}/.json?sort=top&t=week&limit=$amount")
					hot=$(jshon -e data -e children -e $((RANDOM % $amount)) -e data <<< "$input")
				;;
			esac
		;;
	esac
	media_id=$(jshon -e url -u <<< "$hot" | grep "i.redd.it\|imgur\|gfycat")
	if [ "$(grep "gfycat" <<< "$media_id")" != "" ]; then
		media_id=$(curl -s "$media_id" | sed -En 's|.*<source src="(https://thumbs.*mp4)" .*|\1|p')
	fi
	permalink=$(jshon -e permalink -u <<< "$hot")
	title=$(jshon -e title -u <<< "$hot" | sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g')
	stickied=$(jshon -e stickied -u <<< "$hot")
	if [ "$title" != "" ]; then
		caption=$(printf '%s\n' \
			"$title" \
			"link: <a href=\"https://reddit.com$permalink\">$permalink</a>")
	fi
	if [ "$media_id" = "" ]; then
		text_id=$caption
		tg_method send_message > /dev/null
	elif [ "$(grep "jpg\|png" <<< "$media_id")" != "" ]; then
		photo_id=$media_id
		tg_method send_photo > /dev/null
	elif [ "$(grep "gif" <<< "$media_id")" != "" ]; then
		animation_id=$media_id
		tg_method send_animation > /dev/null
	elif [ "$(grep "mp4" <<< "$media_id")" != "" ] && [ "$(ffprobe "$media_id" 2>&1 | grep -o 'Audio:')" = "" ]; then
		animation_id=$media_id
		tg_method send_animation > /dev/null
	elif [ "$(grep "mp4" <<< "$media_id")" != "" ] && [ "$(ffprobe "$media_id" 2>&1 | grep -o 'Audio:')" != "" ]; then
		video_id=$media_id
		tg_method send_video > /dev/null
	fi
}
photo_array() {
    for x in $(seq 0 $j); do
        obj[$x]=$(printf '%s' "{\"type\":\"photo\",\"media\":\"${media[$x]}\"},")
    done
    printf '%s' "[ $(printf '%s' "${obj[@]}" | sed -E 's/(.*)},/\1}/') ]"
}
inline_array() {
	if [ "$j" = "" ]; then
		j=0
	fi
	case $1 in
		article)
			for x in $(seq 0 $j); do
				message_text[$x]=$(sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g' <<< "${message_text[$x]}")
				obj[$x]=$(printf '%s' "{\"type\":\"article\"," \
					"\"id\":\"$RANDOM\"," \
					"\"title\":\"${title[$x]}\"," \
					"\"input_message_content\":" \
						"{\"message_text\":\"${markdown[0]}${message_text[$x]}${markdown[1]}\"," \
						"\"parse_mode\":\"html\"}," \
					"\"description\":\"${description[$x]}\"},")
			done
			printf '%s' "[ $(printf '%s' "${obj[@]}" | sed -E 's/(.*)},/\1}/') ]"
		;;
		photo)
			for x in $(seq 0 $j); do
				obj[$x]=$(printf '%s' "{\"type\":\"photo\"," \
					"\"id\":\"$RANDOM\"," \
					"\"photo_url\":\"${photo_url[$x]}\"," \
					"\"thumb_url\":\"${thumb_url[$x]}\"," \
					"\"caption\":\"${caption[$x]}\"},")
			done
			printf '%s' "[ $(printf '%s' "${obj[@]}" | sed -E 's/(.*)},/\1}/') ]"
		;;
		gif)
			for x in $(seq 0 $j); do
				obj[$x]=$(printf '%s' "{\"type\":\"gif\"," \
					"\"id\":\"$RANDOM\"," \
					"\"gif_url\":\"${gif_url[$x]}\"," \
					"\"thumb_url\":\"${thumb_url[$x]}\"," \
					"\"caption\":\"${caption[$x]}\"},")
			done
			printf '%s' "[ $(printf '%s' "${obj[@]}" | sed -E 's/(.*)},/\1}/') ]"
		;;
		button)
			for x in $(seq 0 $j); do
				obj[$x]=$(printf '%s' "[{\"text\":\"${button_text[$x]}\"," \
					"\"callback_data\":\"${button_text[$x]}\"}],")
			done
			printf '%s' "{\"inline_keyboard\":[$(sed -E 's/(.*)],/\1]/' <<< "${obj[@]}")]}"
		;;
	esac
}
tg_method() {
	case $1 in
		send_message)
			[ -z "$enable_markdown" ] && text_id=$(sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g' <<< "$text_id")
			curl -s "${TELEAPI}/sendMessage" \
			--form-string "chat_id=$chat_id" \
			--form-string "parse_mode=html" \
			--form-string "reply_to_message_id=$reply_id" \
			--form-string "reply_markup=$markup_id" \
			--form-string "text=${markdown[0]}$text_id${markdown[1]}"
		;;
		send_photo)
			curl -s "${TELEAPI}/sendPhoto" \
				-F "chat_id=$chat_id" \
				-F "parse_mode=html" \
				-F "reply_to_message_id=$reply_id" \
				-F "caption=$caption" \
				-F "photo=$photo_id"
		;;
		send_document)
			curl -s "${TELEAPI}/sendDocument" \
				-F "chat_id=$chat_id" \
				-F "parse_mode=html" \
				-F "reply_to_message_id=$reply_id" \
				-F "caption=$caption" \
				-F "document=$document_id"
		;;
		send_video)
			curl -s "$TELEAPI/sendVideo" \
				-F "chat_id=$chat_id" \
				-F "parse_mode=html" \
				-F "reply_to_message_id=$reply_id" \
				-F "thumb=$thumb" \
				-F "caption=$caption" \
				-F "video=$video_id"
		;;
		send_mediagroup)
			curl -s "$TELEAPI/sendMediaGroup" \
				-F "chat_id=$chat_id" \
				-F "parse_mode=html" \
				-F "reply_to_message_id=$reply_id" \
				-F "caption=$caption" \
				-F "media=$mediagroup_id"
		;;
		send_audio)
			curl -s "$TELEAPI/sendAudio" \
				-F "chat_id=$chat_id" \
				-F "parse_mode=html" \
				-F "reply_to_message_id=$reply_id" \
				-F "caption=$caption" \
				-F "audio=$audio_id"
		;;
		send_voice)
			curl -s "$TELEAPI/sendVoice" \
				-F "chat_id=$chat_id" \
				-F "parse_mode=html" \
				-F "reply_to_message_id=$reply_id" \
				-F "caption=$caption" \
				-F "voice=$voice_id"
		;;
		send_animation)
			curl -s "$TELEAPI/sendAnimation" \
				-F "chat_id=$chat_id" \
				-F "parse_mode=html" \
				-F "reply_to_message_id=$reply_id" \
				-F "caption=$caption" \
				-F "animation=$animation_id"
		;;
		send_sticker)
			curl -s "$TELEAPI/sendSticker" \
				-F "chat_id=$chat_id" \
				-F "parse_mode=html" \
				-F "reply_to_message_id=$reply_id" \
				-F "caption=$caption" \
				-F "sticker=$sticker_id"
		;;
		send_inline)
			curl -s "$TELEAPI/answerInlineQuery" \
				--form-string "inline_query_id=$inline_id" \
				--form-string "results=$(sed 's/\\/\\\\/g' <<< "$return_query")" \
				--form-string "next_offset=$offset" \
				--form-string "cache_time=0" \
				--form-string "is_personal=true"
		;;
		forward_message)
			curl -s "$TELEAPI/forwardMessage" \
				--form-string "chat_id=$chat_id" \
				--form-string "from_chat_id=$from_chat_id" \
				--form-string "message_id=$forward_id"
		;;
		inline_reply)
			curl -s "$TELEAPI/answerInlineQuery" \
				--form-string "inline_query_id=$inline_id" \
				--form-string "results=$return_query" \
				--form-string "next_offset=$offset" \
				--form-string "cache_time=100" \
				--form-string "is_personal=true" > /dev/null
		;;
		button_reply)
			curl -s "$TELEAPI/answerCallbackQuery" \
				--form-string "callback_query_id=$callback_id" \
				--form-string "text=$button_text_reply"
		;;
		edit_message)
			curl -s "$TELEAPI/editMessageText" \
				--form-string "chat_id=$chat_id" \
				--form-string "message_id=$to_edit_id" \
				--form-string "text=$edit_text"
		;;
		delete_message)
			curl -s "$TELEAPI/deleteMessage" \
				--form-string "chat_id=$chat_id" \
				--form-string "message_id=$to_delete_id"
		;;
		copy_message)
			curl -s "$TELEAPI/copyMessage" \
				--form-string "chat_id=$chat_id" \
				--form-string "from_chat_id=$from_chat_id" \
				--form-string "message_id=$copy_id"
		;;
		set_chat_permissions)
			curl -s "$TELEAPI/setChatPermissions" \
				-d "$(printf '%s' \
					"{\"chat_id\":\"$chat_id\"," \
					"\"permissions\":{" \
					"\"can_send_messages\":$can_send_messages," \
					"\"can_send_media_messages\":$can_send_media_messages," \
					"\"can_send_other_messages\":$can_send_other_messages," \
					"\"can_send_polls\":$can_send_polls," \
					"\"can_add_web_page_previews\":$can_add_web_page_previews}}")" \
				-H 'Content-Type: application/json'
		;;
		leave_chat)
			curl -s "$TELEAPI/leaveChat" \
				--form-string "chat_id=$chat_id"
		;;
		get_chat)
			curl -s "$TELEAPI/getChat" \
				--form-string "chat_id=$get_chat_id"
		;;
		get_me)
			curl -s "$TELEAPI/getMe"
		;;
	esac
}
get_file_type() {
	[ "$1" = "reply" ] && message=$reply_to_message
	text_id=$(jshon_n -e text -u <<< "$message")
	photo_id=$(jshon_n -e photo -e 0 -e file_id -u <<< "$message")
	animation_id=$(jshon_n -e animation -e file_id -u <<< "$message")
	video_id=$(jshon_n -e video -e file_id -u <<< "$message")
	sticker_id=$(jshon_n -e sticker -e file_id -u <<< "$message")
	audio_id=$(jshon_n -e audio -e file_id -u <<< "$message")
	voice_id=$(jshon_n -e voice -e file_id -u <<< "$message")
	document_id=$(jshon_n -e document -e file_id -u <<< "$message")
	if [ "$text_id" != "" ]; then
		if [ ! -e botinfo ]; then
			tg_method get_me > botinfo
		fi
		text_id=${text_id/@$(jshon_n -e result -e username -u < botinfo)/}
		file_type="text"
	elif [ "$sticker_id" != "" ]; then
		file_type="sticker"
	elif [ "$animation_id" != "" ]; then
		file_type="animation"
	elif [ "$photo_id" != "" ]; then
		file_type="photo"
	elif [ "$video_id" != "" ]; then
		file_type="video"
	elif [ "$audio_id" != "" ]; then
		file_type="audio"
	elif [ "$voice_id" != "" ]; then
		file_type="voice"
	elif [ "$document_id" != "" ]; then
		file_type="document"
	fi
}
get_normal_reply() {
	case $first_normal in
		"${pf}start")
			text_id="this is a mksh bot, use /source to download"
			reply_id=$message_id
			tg_method send_message > /dev/null
		;;
		"${pf}source")
			source_id=$RANDOM
			zip -r source-"$source_id".zip neekshellbot.sh custom_commands LICENSE webhook.php
			document_id="@source-$source_id.zip"
			reply_id=$message_id
			tg_method send_document > /dev/null
			rm source-"$source_id".zip
			text_id="https://gitlab.com/craftmallus/neekshell-telegrambot/"
			tg_method send_message > /dev/null
		;;
		"${pf}help")
			text_id="https://gitlab.com/craftmallus/neekshell-telegrambot/-/blob/master/README.md#commands"
			reply_id=$message_id
			tg_method send_message > /dev/null
		;;
	esac
}
get_inline_reply() {
	case $results in
		"ok")
			title="Ok"
			message_text="Ok"
			description="Alright"
			return_query=$(inline_array article)
			tg_method send_inline > /dev/null
		;;
	esac
}
get_button_reply() {
	case $callback_message_text in
		test)
			text_id="$callback_data"
			tg_method button_reply > /dev/null
			chat_id=$callback_user_id
			tg_method send_message > /dev/null
		;;
	esac
}
process_reply() {
	message=$(jshon_n -e message <<< "$input")
	inline=$(jshon_n -e inline_query <<< "$input")
	callback=$(jshon_n -e callback_query <<< "$input")
	type=$(jshon_n -e chat -e type -u <<< "$message")
	chat_id=$(jshon_n -e chat -e id -u <<< "$message")
	username_id=$(jshon_n -e from -e id -u <<< "$message")
	if [ "$type" = "private" ] || [ "$inline" != "" ] || [ "$callback" != "" ]; then
		bot_chat_dir="db/bot_chats/"
		bot_chat_user_id=$username_id
	else
		bot_chat_dir="db/bot_group_chats/"
		bot_chat_user_id=$chat_id
		in_bgc=$(grep -r -- "$bot_chat_user_id" "$bot_chat_dir")
	fi
	if [ "$(jshon_n -e text -u <<< "$message" | grep '^!\|^/\|^+\|^-')" = "" ] \
	&& [ "$type" != "private" ] \
	&& [ "$inline" = "" ] \
	&& [ "$callback" = "" ]; then
		if [ "$in_bgc" = "" ]; then
			exit
		fi
	fi

	# user database
	username_tag=$(jshon_n -e from -e username -u <<< "$message")
	username_fname=$(jshon_n -e from -e first_name -u <<< "$message")
	username_lname=$(jshon_n -e from -e last_name -u <<< "$message")
	if [ "$username_id" != "" ]; then
		[ ! -d db/users/ ] && mkdir -p db/users/
		file_user=db/users/"$username_id"
		if [ ! -e "$file_user" ]; then
			[ "$username_tag" = "" ] && username_tag="(empty)"
			printf '%s\n' \
			"tag: $username_tag" \
			"id: $username_id" \
			"fname: $username_fname" \
			"lname: $username_lname" > "$file_user"
		fi
		if [ "tag: $username_tag" != "$(grep -- "tag" "$file_user")" ]; then
			sed -i "s/tag: .*/tag: $username_tag/" "$file_user"
		fi
		if [ "fname: $username_fname" != "$(grep -- "fname" "$file_user")" ]; then
			sed -i "s/fname: .*/fname: $username_fname/" "$file_user"
		fi
		if [ "lname: $username_fname" != "$(grep -- "lname" "$file_user")" ]; then
			sed -i "s/lname: .*/lname: $username_lname/" "$file_user"
		fi
	fi
	reply_to_message=$(jshon_n -e reply_to_message <<< "$message")
	if [ "$reply_to_message" != "" ]; then
		reply_to_id=$(jshon_n -e message_id -u <<< "$reply_to_message")
		reply_to_user_id=$(jshon_n -e from -e id -u <<< "$reply_to_message")
		reply_to_user_tag=$(jshon_n -e from -e username -u <<< \
			"$reply_to_message")
		reply_to_user_fname=$(jshon_n -e from -e first_name -u \
			<<< "$reply_to_message")
		reply_to_user_lname=$(jshon_n -e from -e last_name -u \
			<<< "$reply_to_message")
		reply_to_text=$(jshon_n -e text -u <<< "$reply_to_message")
		[ ! -d db/users/ ] && mkdir -p db/users/
		file_reply_user=db/users/"$reply_to_user_id"
		if [ ! -e "$file_reply_user" ]; then
			[ "$reply_to_user_tag" = "" ] && reply_to_user_tag="(empty)"
			printf '%s\n' \
			"tag: $reply_to_user_tag" \
			"id: $reply_to_user_id" \
			"fname: $reply_to_user_fname" \
			"lname: $reply_to_user_lname" > "$file_reply_user"
		fi
	fi
	# chat database
	chat_title=$(jshon_n -e chat -e title -u <<< "$message")
	if [ "$chat_title" != "" ]; then
		[ ! -d db/chats/ ] && mkdir -p db/chats/
		file_chat=db/chats/"$chat_id"
		if [ ! -e "$file_chat" ]; then
			printf '%s\n' \
			"title: $chat_title" \
			"id: $chat_id" \
			"type: $type" > "$file_chat"
		fi
	fi

	callback_user=$(jshon_n -e from -e username -u <<< "$callback")
	callback_user_id=$(jshon_n -e from -e id -u <<< "$callback")
	callback_id=$(jshon_n -e id -u <<< "$callback")
	callback_data=$(jshon_n -e data -u <<< "$callback")
	callback_message_text=$(jshon_n -e message -e text -u <<< "$callback")

	message_id=$(jshon_n -e message_id -u <<< "$message")

	inline_user=$(jshon_n -e from -e username -u <<< "$inline")
	inline_user_id=$(jshon_n -e from -e id -u <<< "$inline")
	inline_id=$(jshon_n -e id -u <<< "$inline")
	results=$(jshon_n -e query -u <<< "$inline")

	get_file_type

	case "$file_type" in
		text)
			first_normal=$text_id
		;;
		photo)
			first_normal=$photo_id
		;;
		animation)
			first_normal=$animation_id
		;;
		video)
			first_normal=$video_id
		;;
		sticker)
			first_normal=$sticker_id
		;;
		audio)
			first_normal=$audio_id
		;;
		voice)
			first_normal=$voice_id
		;;
		document)
			first_normal=$document_id
		;;
	esac

	pf=$(grep -o -- '^.' <<< "$text_id")
	if [ "$pf" != '!' ] && [ "$pf" != '/' ]; then
		pf=""
	fi

	if [ "$first_normal" != "" ]; then
		get_normal_reply
		source custom_commands/normal_reply.sh
	elif [ "$results" != "" ]; then
		get_inline_reply
		source custom_commands/inline_reply.sh
	elif [ "$callback_data" != "" ]; then
		get_button_reply
		source custom_commands/button_reply.sh
	fi
}
input=$1
process_reply
END_TIME=$(bc <<< "$(date +%s%N) / 1000000")
printf '%s\n' "[$(date "+%F %H:%M:%S")] elapsed time: $(($END_TIME - $START_TIME))ms"
