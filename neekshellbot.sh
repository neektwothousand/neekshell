#!/bin/mksh
set -a
LC_ALL=C
START_TIME=$(bc <<< "$(date +%s%N) / 1000000")
PS4="[$(date "+%F %H:%M:%S")] "
exec 1>>"log.log" 2>&1
TOKEN=$(cat ./token)
TELEAPI="https://api.telegram.org/bot${TOKEN}"
update_db() {
	if [[ "$user_id" != "" ]]; then
		[[ ! -d db/users/ ]] && mkdir -p db/users/
		file_user=db/users/"$user_id"
		if [[ ! -e "$file_user" ]]; then
			printf '%s\n' \
			"tag: $user_tag" \
			"id: $user_id" \
			"fname: $user_fname" \
			"lname: $user_lname" > "$file_user"
		fi
		if [[ "tag: $user_tag" != "$(grep -- "^tag" "$file_user")" ]]; then
			sed -i "s/^tag: .*/tag: $user_tag/" "$file_user"
		fi
		if [[ "fname: $user_fname" != "$(grep -- "^fname" "$file_user")" ]]; then
			sed -i "s/^fname: .*/fname: $user_fname/" "$file_user"
		fi
		if [[ "lname: $user_lname" != "$(grep -- "^lname" "$file_user")" ]]; then
			sed -i "s/^lname: .*/lname: $user_lname/" "$file_user"
		fi
	fi
	if [[ "$reply_to_message" != "" ]]; then
		[[ ! -d db/users/ ]] && mkdir -p db/users/
		file_reply_user=db/users/"$reply_to_user_id"
		if [[ ! -e "$file_reply_user" ]]; then
			printf '%s\n' \
				"tag: $reply_to_user_tag" \
				"id: $reply_to_user_id" \
				"fname: $reply_to_user_fname" \
				"lname: $reply_to_user_lname" > "$file_reply_user"
		fi
	fi
	if [[ "$chat_id" != "" ]]; then
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
}
is_admin() {
	grep -w -- "^$user_id\|^$inline_user_id\|^$callback_user_id" admins
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
json_array() {
	case "$1" in
		mediagroup)
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
		;;
		inline)
			if [[ "$j" = "" ]]; then
				j=0
			fi
			case "$2" in
				article)
					for x in $(seq 0 $j); do
						message_text[$x]="${markdown[0]}$(sed -e "s/\\\\/\\\\\\\/g" -e 's/"/\\"/g' -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g' <<< "${message_text[$x]}" | perl -pe 's/\n/\\n/g')${markdown[1]}"
						title[$x]="$(sed -e 's/"/\\"/g' -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g' <<< "${title[$x]}" | perl -pe 's/\n/\\n/g')"
						description[$x]="$(sed -e 's/"/\\"/g' -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g' <<< "${description[$x]}" | perl -pe 's/\n/\\n/g')"
						obj[$x]=$(printf '%s' "{\"type\":\"article\"," \
							"\"id\":\"$RANDOM\"," \
							"\"title\":\"${title[$x]}\"," \
							"\"input_message_content\":" \
								"{\"message_text\":\"${message_text[$x]}\"," \
								"\"parse_mode\":\"html\"}," \
							"\"description\":\"${description[$x]}\"},")
					done
					printf '%s' "[ $(printf '%s' "${obj[@]}" | head -c -1) ]"
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
		;;
	esac
}
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
get_file_type() {
	[[ "$1" = "reply" ]] && message=$reply_to_message
	if [[ "$(jshon -Q -e text -u <<< "$message")" != "" ]]; then
		text_id=$(jshon -Q -e text -u <<< "$message")
		if [[ ! -e botinfo ]]; then
			tg_method get_me > botinfo
		fi
		text_id=${text_id/@$(jshon -Q -e result -e username -u < botinfo)/}
		file_type="text"
	elif [[ "$(jshon -Q -e sticker -e file_id -u <<< "$message")" != "" ]]; then
		sticker_id=$(jshon -Q -e sticker -e file_id -u <<< "$message")
		file_type="sticker"
	elif [[ "$(jshon -Q -e animation -e file_id -u <<< "$message")" != "" ]]; then
		animation_id=$(jshon -Q -e animation -e file_id -u <<< "$message")
		file_type="animation"
	elif [[ "$(jshon -Q -e photo -e 0 -e file_id -u <<< "$message")" != "" ]]; then
		photo_id=$(jshon -Q -e photo -e 0 -e file_id -u <<< "$message")
		file_type="photo"
	elif [[ "$(jshon -Q -e video -e file_id -u <<< "$message")" != "" ]]; then
		video_id=$(jshon -Q -e video -e file_id -u <<< "$message")
		file_type="video"
	elif [[ "$(jshon -Q -e audio -e file_id -u <<< "$message")" != "" ]]; then
		audio_id=$(jshon -Q -e audio -e file_id -u <<< "$message")
		file_type="audio"
	elif [[ "$(jshon -Q -e voice -e file_id -u <<< "$message")" != "" ]]; then
		voice_id=$(jshon -Q -e voice -e file_id -u <<< "$message")
		file_type="voice"
	elif [[ "$(jshon -Q -e document -e file_id -u <<< "$message")" != "" ]]; then
		document_id=$(jshon -Q -e document -e file_id -u <<< "$message")
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
			if [[ "$fn_args" = "" ]]; then
				text_id=$(printf '%s\n' "$(cat help/* | grep -A 1 '^Usage' | grep -v '^Usage\|--' | sed 's/^  //' | sort)" "" "send !help <command> for details")
			else
				text_id=$(cat help/"$fn_args")
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
			return_query=$(json_array inline article)
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
	if [[ "$message" != "" ]]; then
		message_id=$(jshon -Q -e message_id -u <<< "$message")
		type=$(jshon -Q -e chat -e type -u <<< "$message")
		chat_id=$(jshon -Q -e chat -e id -u <<< "$message")
		chat_title=$(jshon -Q -e chat -e title -u <<< "$message")
		user_id=$(jshon -Q -e from -e id -u <<< "$message")
		reply_to_message=$(jshon -Q -e reply_to_message <<< "$message")
		if [[ "$(grep -w -- "777000\|1087968824" <<< "$user_id")" = "" ]]; then
			user_tag=$(jshon -Q -e from -e username -u <<< "$message")
			user_fname=$(jshon -Q -e from -e first_name -u <<< "$message")
			user_lname=$(jshon -Q -e from -e last_name -u <<< "$message")
		else
			user_id=$(jshon -Q -e sender_chat -e id -u <<< "$message")
			user_tag=$(jshon -Q -e sender_chat -e username -u <<< "$message")
			user_fname=$(jshon -Q -e sender_chat -e title -u <<< "$message")
		fi
		if [[ "$reply_to_message" != "" ]]; then
			reply_to_id=$(jshon -Q -e message_id -u <<< "$reply_to_message")
			reply_to_user_id=$(jshon -Q -e from -e id -u <<< "$reply_to_message")
			reply_to_text=$(jshon -Q -e text -u <<< "$reply_to_message")
			reply_to_caption=$(jshon -Q -e caption -u <<< "$reply_to_message")
			if [[ "$(grep -w -- "777000\|1087968824" <<< "$reply_to_user_id")" != "" ]]; then
				reply_to_user_id=$(jshon -Q -e sender_chat -e id -u <<< "$reply_to_message")
				reply_to_user_tag=$(jshon -Q -e sender_chat -e username -u <<< "$reply_to_message")
				reply_to_user_fname=$reply_to_user_tag
			else
				reply_to_user_tag=$(jshon -Q -e from -e username -u <<< "$reply_to_message")
				reply_to_user_fname=$(jshon -Q -e from -e first_name -u <<< "$reply_to_message")
				reply_to_user_lname=$(jshon -Q -e from -e last_name -u <<< "$reply_to_message")
			fi
		fi
	elif [[ "$callback" != "" ]]; then
		callback_user=$(jshon -Q -e from -e username -u <<< "$callback")
		callback_user_id=$(jshon -Q -e from -e id -u <<< "$callback")
		callback_fname=$(jshon -Q -e from -e first_name -u <<< "$callback")
		callback_lname=$(jshon -Q -e from -e last_name -u <<< "$callback")
		callback_id=$(jshon -Q -e id -u <<< "$callback")
		callback_data=$(jshon -Q -e data -u <<< "$callback")
		callback_message_text=$(jshon -Q -e message -e text -u <<< "$callback")
		user_id=$callback_user_id user_fname=$callback_fname
	elif [[ "$inline" != "" ]]; then
		inline_user_id=$(jshon -Q -e from -e id -u <<< "$inline")
		inline_id=$(jshon -Q -e id -u <<< "$inline")
		inline_user=$(jshon -Q -e from -e username -u <<< "$inline")
		inline_user_id=$(jshon -Q -e from -e id -u <<< "$inline")
		inline_fname=$(jshon -Q -e from -e first_name -u <<< "$inline")
		inline_lname=$(jshon -Q -e from -e last_name -u <<< "$inline")
		inline_message=$(jshon -Q -e query -u <<< "$inline")
		im_arg=$(cut -f 2- -d ' ' <<< "$inline_message")
		user_id=$inline_user_id user_fname=$inline_fname
	fi
	if [[ $(grep -w -- "^$user_id\|^$inline_user_id\|^$callback_user_id" banned) ]]; then
		user_fname="banned"
		return
	else
		if [[ "$type" = "private" ]] || [[ "$inline" != "" ]] || [[ "$callback" != "" ]]; then
			bot_chat_dir="db/bot_chats/"
			bot_chat_user_id=$user_id
		else
			bot_chat_dir="db/bot_group_chats/"
			bot_chat_user_id=$chat_id
		fi
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
				unset text_id
				fn_args=$(cut -f 2- -d ' ' <<< "$normal_message")
				if [[ "$fn_args" != "$normal_message" ]]; then
					for x in $(seq 0 $(( $(wc -l <<< "$(tr ' ' '\n' <<< "$fn_args")")-1))); do
						fn_arg[$x]=$(cut -f $(($x+1)) -d ' ' <<< "$fn_args")
					done
				else
					fn_args=""
				fi
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
		update_db
		source tg_method.sh
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
	fi
}
input=$1
basedir=$(realpath .)
tmpdir="/tmp/neekshell"
[[ ! -d $tmpdir ]] && mkdir $tmpdir
process_reply
END_TIME=$(bc <<< "$(date +%s%N) / 1000000")
[[ ! -d stats/users ]] && mkdir -p stats/users
[[ ! -d stats/chats ]] && mkdir -p stats/chats
if [[ "$user_id" != "" ]]; then # usage in ms per user
	if [[ ! -e "stats/users/$user_id-usage" ]]; then
		printf '%s\n' "$(($END_TIME - $START_TIME)):$user_id ($user_fname)" > "stats/users/$user_id-usage"
	else
		printf '%s\n' "$((($END_TIME - $START_TIME)+$(cut -f 1 -d : < "stats/users/$user_id-usage"))):$user_id ($user_fname)" > "stats/users/$user_id-usage"
	fi
fi
if [[ "$chat_id" != "" ]]; then # usage in messages per chat
	if [[ ! -e "stats/chats/$chat_id-usage" ]]; then
		printf '%s\n' "1:$chat_id ($chat_title)" > "stats/chats/$chat_id-usage"
	else
		printf '%s\n' "$((1+$(cut -f 1 -d : < "stats/chats/$chat_id-usage"))):$chat_id ($chat_title)" > "stats/chats/$chat_id-usage"
	fi
fi
printf '%s\n' "[$(date "+%F %H:%M:%S")] elapsed time: $(($END_TIME - $START_TIME))ms"
