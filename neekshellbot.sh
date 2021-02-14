#!/bin/mksh
START_TIME=$(bc <<< "$(date +%s%N) / 1000000")
PS4="[$(date "+%F %H:%M:%S")] "
exec 1>>"log.log" 2>&1
set -a
TOKEN=$(cat ./token)
TELEAPI="https://api.telegram.org/bot${TOKEN}"
source tg_method.sh
get_reply_id() {
	case $1 in
		any)
			if [[ "$reply_to_message" != "" ]]; then
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
	grep -v "#" admins | grep -w -- "$username_id\|$inline_user_id"
}
loading() {
	case $1 in
		1)
			text_id="processing ..."
			processing_id=$(tg_method send_message | jshon -Q -e result -e message_id -u)
		;;
		value)
			edit_id=$processing_id
			edit_text="$2"
			tg_method edit_text
		;;
		2)
			edit_id=$processing_id
			edit_text="sending..."
			tg_method edit_text > /dev/null
		;;
		3)
			to_delete_id=$processing_id
			tg_method delete_message > /dev/null
		;;
	esac
}
r_subreddit() {
	[[ "$1" = "" ]] && exit
	enable_markdown=true
	parse_mode=html
	case "$subreddit" in
		none)
			case "$filter" in
				random)
					r_input=$(wget -q -O- "https://reddit.com/random/.json")
					hot=$(jshon -e 0 -e data -e children -e 0 -e data <<< "$r_input")
				;;
			esac
		;;
		"https"*)
			if [[ "$(grep "reddit.com" <<< "$subreddit")" != "" ]]; then
				if [[ "$(grep '?' <<< "$subreddit")" != "" ]]; then
					subreddit=$(sed 's/\?.*//' <<< "$subreddit")
				fi
				r_input=$(wget -q -O- "$subreddit/.json")
			else
				text_id="invalid link"
				get_reply_id any
				tg_method send_message > /dev/null
				return
			fi
			hot=$(jshon -e 0 -e data -e children -e 0 -e data <<< "$r_input")
		;;
		*)
			case "$filter" in
				random)
					r_input=$(wget -q -O- "https://reddit.com/r/${subreddit}/random/.json")
					hot=$(jshon -e 0 -e data -e children -e 0 -e data <<< "$r_input")
				;;
				*)
					amount=10
					r_input=$(wget -q -O- "https://reddit.com/r/${subreddit}/.json?sort=top&t=week&limit=$amount")
					hot=$(jshon -e data -e children -e $((RANDOM % $amount)) -e data <<< "$r_input")
					if [[ "$filter" = "pic" ]] \
					&& [[ "$(jshon -e url -u <<< "$hot" | grep "i.redd.it\|imgur" | grep "jpg\|png")" = "" ]]; then
						x=0
						while [[ "$s_pic" != "found" ]]; do
							hot=$(jshon -e data -e children -e $x -e data <<< "$r_input")
							pic=$(jshon -e url -u <<< "$hot" | grep "i.redd.it\|imgur" | grep "jpg\|png")
							x=$((x+1))
							if [[ "$pic" != "" ]]; then
								s_pic="found"
							fi
							if [[ $x -gt 10 ]]; then
								text_id="pic not found"
								tg_method send_message > /dev/null
								return
							fi
						done
					fi
				;;
			esac
		;;
	esac
	media_id=$(jshon -e url -u <<< "$hot" | grep "i.redd.it\|imgur\|gfycat\|redgifs")
	if [[ "$(grep "gfycat" <<< "$media_id")" != "" ]]; then
		media_id=$(curl -s "$media_id" | sed -En 's|.*<source src="(https://thumbs.*mp4)" .*|\1|p')
	elif [[ "$(grep "redgifs" <<< "$media_id")" != "" ]]; then
		media_id=$(wget -q -O- "$media_id" | sed -En 's|.*content="(https://thumbs2.redgifs.*-mobile.mp4)".*|\1|p')
	fi
	permalink=$(jshon -e permalink -u <<< "$hot" | cut -f 5 -d /)
	title=$(jshon -e title -u <<< "$hot")
	stickied=$(jshon -e stickied -u <<< "$hot")
	if [[ "$title" != "" ]]; then
		caption=$(printf '%s\n' \
			"$title" \
			"link: redd.it/$permalink")
	fi
	if [[ "$media_id" = "" ]]; then
		text_id=$caption
		tg_method send_message > /dev/null
	elif [[ "$(grep "jpg\|png" <<< "$media_id")" != "" ]]; then
		photo_id=$media_id
		if [[ "$(tg_method send_photo | jshon -Q -e ok)" = "false" ]]; then
			text_id=$caption
			tg_method send_message > /dev/null
		fi
	elif [[ "$(grep "gif" <<< "$media_id")" != "" ]]; then
		animation_id=$media_id
		if [[ "$(tg_method send_animation | jshon -Q -e ok)" = "false" ]]; then
			text_id=$caption
			tg_method send_message > /dev/null
		fi
	elif [[ "$(grep "mp4" <<< "$media_id")" != "" ]] && [[ "$(ffprobe "$media_id" 2>&1 | grep -o 'Audio:')" = "" ]]; then
		animation_id=$media_id
		if [[ "$(tg_method send_animation | jshon -Q -e ok)" = "false" ]]; then
			text_id=$caption
			tg_method send_message > /dev/null
		fi
	elif [[ "$(grep "mp4" <<< "$media_id")" != "" ]] && [[ "$(ffprobe "$media_id" 2>&1 | grep -o 'Audio:')" != "" ]]; then
		video_id=$media_id
		if [[ "$(tg_method send_video | jshon -Q -e ok)" = "false" ]]; then
			text_id=$caption
			tg_method send_message > /dev/null
		fi
	fi
}
photo_array() {
	for x in $(seq 0 $j); do
        if [ "${caption}" != "" ]; then
			obj[$x]="{
			\"type\":\"photo\",
			\"media\":\"${media[$x]}\",
			\"caption\":\"${caption}\"
			},"
        else
			obj[$x]="{
			\"type\":\"photo\",
			\"media\":\"${media[$x]}\"
			},"
        fi
        caption=""
    done
	printf '%s' "[ $(printf '%s' "${obj[@]}" | head -c -1) ]"
}
inline_array() {
	if [[ "$j" = "" ]]; then
		j=0
	fi
	case $1 in
		article)
			for x in $(seq 0 $j); do
				message_text[$x]=$(sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g' <<< "${message_text[$x]}")
				title[$x]=$(sed 's/"//g' <<< "${title[$x]}")
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
			[[ "$button_data" = "" ]] && button_data=("${button_text[@]}")
			for x in $(seq 0 $j); do
				obj[$x]=$(printf '%s' "[{\"text\":\"${button_text[$x]}\"," \
					"\"callback_data\":\"${button_data[$x]}\"}],")
			done
			printf '%s' "{\"inline_keyboard\":[$(sed -E 's/(.*)],/\1]/' <<< "${obj[@]}")]}"
		;;
	esac
}
get_file_type() {
	[[ "$1" = "reply" ]] && message=$reply_to_message
	text_id=$(jshon -Q -e text -u <<< "$message")
	photo_id=$(jshon -Q -e photo -e 0 -e file_id -u <<< "$message")
	animation_id=$(jshon -Q -e animation -e file_id -u <<< "$message")
	video_id=$(jshon -Q -e video -e file_id -u <<< "$message")
	sticker_id=$(jshon -Q -e sticker -e file_id -u <<< "$message")
	audio_id=$(jshon -Q -e audio -e file_id -u <<< "$message")
	voice_id=$(jshon -Q -e voice -e file_id -u <<< "$message")
	document_id=$(jshon -Q -e document -e file_id -u <<< "$message")
	if [[ "$text_id" != "" ]]; then
		if [[ ! -e botinfo ]]; then
			tg_method get_me > botinfo
		fi
		text_id=${text_id/@$(jshon -Q -e result -e username -u < botinfo)/}
		file_type="text"
	elif [[ "$sticker_id" != "" ]]; then
		file_type="sticker"
	elif [[ "$animation_id" != "" ]]; then
		file_type="animation"
	elif [[ "$photo_id" != "" ]]; then
		file_type="photo"
	elif [[ "$video_id" != "" ]]; then
		file_type="video"
	elif [[ "$audio_id" != "" ]]; then
		file_type="audio"
	elif [[ "$voice_id" != "" ]]; then
		file_type="voice"
	elif [[ "$document_id" != "" ]]; then
		file_type="document"
	fi
}
get_normal_reply() {
	case $normal_message in
		"!start")
			text_id="this is a mksh bot, use !source to download"
			get_reply_id self
			tg_method send_message > /dev/null
		;;
		"!help"|"!help "*)
			if [[ "$fn_arg" = "" ]]; then
				text_id=$(printf '%s\n' "$(cat help/* | grep -A 1 '^Usage' | grep -v '^Usage\|--' | sed 's/^  //' | sort)" "" "send !help <command> for details")
			else
				text_id=$(cat help/"$fn_arg")
				[[ "$text_id" = "" ]] && text_id="command not found"
			fi
			get_reply_id self
			tg_method send_message > /dev/null
		;;
		"!source")
			source_id=$RANDOM
			zip -r source-"$source_id".zip neekshellbot.sh custom_commands LICENSE README.md webhook.php
			document_id="@source-$source_id.zip"
			get_reply_id self
			tg_method send_document upload > /dev/null
			rm source-"$source_id".zip
			text_id="https://gitlab.com/craftmallus/neekshell-telegrambot/"
			tg_method send_message > /dev/null
		;;
	esac
}
get_inline_reply() {
	case $inline_message in
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
	message_type=$(jshon -Q <<< "$input" | sed -n 3p | sed -e 's/^\s"//' -e 's/".*//')
	case "$message_type" in
		message)
			message=$(jshon -Q -e message <<< "$input")
		;;
		channel_post)
			message=$(jshon -Q -e channel_post <<< "$input")
		;;
	esac
	inline=$(jshon -Q -e inline_query <<< "$input")
	callback=$(jshon -Q -e callback_query <<< "$input")
	type=$(jshon -Q -e chat -e type -u <<< "$message")
	chat_id=$(jshon -Q -e chat -e id -u <<< "$message")
	username_id=$(jshon -Q -e from -e id -u <<< "$message")
	if [[ "$type" = "private" ]] || [[ "$inline" != "" ]] || [[ "$callback" != "" ]]; then
		bot_chat_dir="db/bot_chats/"
		bot_chat_user_id=$username_id
	else
		bot_chat_dir="db/bot_group_chats/"
		bot_chat_user_id=$chat_id
	fi

	# user database
	username_tag=$(jshon -Q -e from -e username -u <<< "$message")
	username_fname=$(jshon -Q -e from -e first_name -u <<< "$message")
	username_lname=$(jshon -Q -e from -e last_name -u <<< "$message")
	if [[ "$username_id" != "" ]]; then
		[[ ! -d db/users/ ]] && mkdir -p db/users/
		file_user=db/users/"$username_id"
		if [[ ! -e "$file_user" ]]; then
			[[ "$username_tag" = "" ]] && username_tag="(empty)"
			printf '%s\n' \
			"tag: $username_tag" \
			"id: $username_id" \
			"fname: $username_fname" \
			"lname: $username_lname" > "$file_user"
		fi
		if [[ "tag: $username_tag" != "$(grep -- "^tag" "$file_user")" ]]; then
			sed -i "s/^tag: .*/tag: $username_tag/" "$file_user"
		fi
		if [[ "fname: $username_fname" != "$(grep -- "^fname" "$file_user")" ]]; then
			sed -i "s/^fname: .*/fname: $username_fname/" "$file_user"
		fi
		if [[ "lname: $username_lname" != "$(grep -- "^lname" "$file_user")" ]]; then
			sed -i "s/^lname: .*/lname: $username_lname/" "$file_user"
		fi
	fi
	reply_to_message=$(jshon -Q -e reply_to_message <<< "$message")
	if [[ "$reply_to_message" != "" ]]; then
		reply_to_id=$(jshon -Q -e message_id -u <<< "$reply_to_message")
		reply_to_user_id=$(jshon -Q -e from -e id -u <<< "$reply_to_message")
		if [[ "$reply_to_user_id" = "777000" ]]; then
			reply_to_user_id=$(jshon -Q -e sender_chat -e id -u <<< "$reply_to_message")
			reply_to_user_tag=$(jshon -Q -e sender_chat -e username -u <<< \
				"$reply_to_message")
			reply_to_user_fname=$reply_to_user_tag
		else
			reply_to_user_tag=$(jshon -Q -e from -e username -u <<< \
				"$reply_to_message")
			reply_to_user_fname=$(jshon -Q -e from -e first_name -u \
				<<< "$reply_to_message")
			reply_to_user_lname=$(jshon -Q -e from -e last_name -u \
				<<< "$reply_to_message")
		fi
		reply_to_text=$(jshon -Q -e text -u <<< "$reply_to_message")
		reply_to_caption=$(jshon -Q -e caption -u <<< "$reply_to_message")
		[[ ! -d db/users/ ]] && mkdir -p db/users/
		file_reply_user=db/users/"$reply_to_user_id"
		if [[ ! -e "$file_reply_user" ]]; then
			[[ "$reply_to_user_tag" = "" ]] && reply_to_user_tag="(empty)"
			printf '%s\n' \
			"tag: $reply_to_user_tag" \
			"id: $reply_to_user_id" \
			"fname: $reply_to_user_fname" \
			"lname: $reply_to_user_lname" > "$file_reply_user"
		fi
	fi
	# chat database
	chat_title=$(jshon -Q -e chat -e title -u <<< "$message")
	if [[ "$chat_title" != "" ]]; then
		[[ ! -d db/chats/ ]] && mkdir -p db/chats/
		file_chat=db/chats/"$chat_id"
		if [[ ! -e "$file_chat" ]]; then
			printf '%s\n' \
			"title: $chat_title" \
			"id: $chat_id" \
			"type: $type" > "$file_chat"
		fi
		if [[ "title: $chat_title" != "$(grep -- "^title" "$file_chat")" ]]; then
			sed -i "s/^title: .*/title: $chat_title/" "$file_chat"
		fi
	fi

	callback_user=$(jshon -Q -e from -e username -u <<< "$callback")
	callback_user_id=$(jshon -Q -e from -e id -u <<< "$callback")
	callback_id=$(jshon -Q -e id -u <<< "$callback")
	callback_data=$(jshon -Q -e data -u <<< "$callback")
	callback_message_text=$(jshon -Q -e message -e text -u <<< "$callback")

	message_id=$(jshon -Q -e message_id -u <<< "$message")

	inline_user=$(jshon -Q -e from -e username -u <<< "$inline")
	inline_user_id=$(jshon -Q -e from -e id -u <<< "$inline")
	inline_id=$(jshon -Q -e id -u <<< "$inline")
	inline_message=$(jshon -Q -e query -u <<< "$inline")
	im_arg=$(cut -f 2- -d ' ' <<< "$inline_message")

	get_file_type

	case "$file_type" in
		text)
			pf=$(grep -o '^.' <<< "$text_id")
			case "$pf" in
				"/"|"$"|"&"|"%"|";")
					normal_message=$(sed "s|^[$pf]|!|" <<< "$text_id")
				;;
				*)
					normal_message=$text_id
			esac
			fn_arg=$(cut -f 2- -d ' ' <<< "$normal_message")
			[[ "$fn_arg" = "$normal_message" ]] && fn_arg=""
		;;
		photo)
			normal_message=$photo_id
		;;
		animation)
			normal_message=$animation_id
		;;
		video)
			normal_message=$video_id
		;;
		sticker)
			normal_message=$sticker_id
		;;
		audio)
			normal_message=$audio_id
		;;
		voice)
			normal_message=$voice_id
		;;
		document)
			normal_message=$document_id
		;;
	esac

	if [[ "$normal_message" != "" ]]; then
		get_normal_reply
		source custom_commands/normal_reply.sh
	elif [[ "$inline_message" != "" ]]; then
		get_inline_reply
		source custom_commands/inline_reply.sh
	elif [[ "$callback_data" != "" ]]; then
		get_button_reply
		source custom_commands/button_reply.sh
	fi
}
input=$1
tmpdir="/tmp/neekshell"
[[ ! -d $tmpdir ]] && mkdir -p $tmpdir
process_reply
END_TIME=$(bc <<< "$(date +%s%N) / 1000000")
printf '%s\n' "[$(date "+%F %H:%M:%S")] elapsed time: $(($END_TIME - $START_TIME))ms"
