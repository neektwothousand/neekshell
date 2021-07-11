#!/bin/mksh
set -f
START_TIME=$(bc <<< "$(date +%s%N) / 1000000")
PS4="[$(date "+%F %H:%M:%S")] "
exec 1>>"log.log" 2>&1
TOKEN=$(cat ./token)
TELEAPI="http://192.168.1.15:8081/bot${TOKEN}"
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
		else
			if [[ "tag: $user_tag" != "$(grep -- "^tag" "$file_user")" ]]; then
				sed -i "s/^tag: .*/tag: $user_tag/" "$file_user"
			fi
			if [[ "fname: $user_fname" != "$(grep -- "^fname" "$file_user")" ]]; then
				sed -i "s/^fname: .*/fname: $(sed 's|/|\\/|'<<< "$user_fname")/" "$file_user"
			fi
			if [[ "lname: $user_lname" != "$(grep -- "^lname" "$file_user")" ]]; then
				sed -i "s/^lname: .*/lname: $(sed 's|/|\\/|'<<< "$user_lname")/" "$file_user"
			fi
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
		else
			if [[ "title: $chat_title" != "$(grep -- "^title" "$file_chat")" ]]; then
				sed -i "s/^title: .*/title: $chat_title/" "$file_chat"
			fi
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
			tg_method send_message
			processing_id=$(jshon -Q -e result -e message_id -u <<< "$curl_result")
		;;
		value)
			edit_id=$processing_id
			edit_text="$2"
			tg_method edit_text
		;;
		2)
			edit_id=$processing_id
			edit_text="sending..."
			tg_method edit_text
		;;
		3)
			to_delete_id=$processing_id
			tg_method delete_message
		;;
	esac
}
json_array() {
	case "$1" in
		mediagroup)
			if [[ "${caption}" != "" ]]; then
				obj[0]="{
					\"type\":\"photo\",
					\"media\":\"${media[0]}\",
					\"caption\":\"${caption}\"
				},"
				for x in $(seq 1 $j); do
					obj[$x]="{
						\"type\":\"photo\",
						\"media\":\"${media[$x]}\"
					},"
				done
			else
				for x in $(seq 0 $j); do
					obj[$x]="{
						\"type\":\"photo\",
						\"media\":\"${media[$x]}\"
					},"
				done
			fi
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
						if [[ "${markup_id[$x]}" != "" ]]; then
							obj[$x]=$(printf '%s' "{\"type\":\"article\"," \
								"\"id\":\"$RANDOM\"," \
								"\"title\":\"${title[$x]}\"," \
								"\"input_message_content\":" \
									"{\"message_text\":\"${message_text[$x]}\"," \
									"\"parse_mode\":\"html\"}," \
								"\"reply_markup\":${markup_id[$x]}," \
								"\"description\":\"${description[$x]}\"},")
						else
							obj[$x]=$(printf '%s' "{\"type\":\"article\"," \
								"\"id\":\"$RANDOM\"," \
								"\"title\":\"${title[$x]}\"," \
								"\"input_message_content\":" \
									"{\"message_text\":\"${message_text[$x]}\"," \
									"\"parse_mode\":\"html\"}," \
								"\"description\":\"${description[$x]}\"},")
						fi
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
					if [[ "$button_data" == "" ]] && [[ "$button_url" == "" ]]; then
						button_data=("${button_text[@]}")
					fi
					if [[ "$button_data" != "" ]]; then
						for x in $(seq 0 $j); do
							obj[$x]=$(printf '%s' "[{\"text\":\"${button_text[$x]}\"," \
								"\"callback_data\":\"${button_data[$x]}\"}],")
						done
					elif [[ "$button_url" != "" ]]; then
						for x in $(seq 0 $j); do
							obj[$x]=$(printf '%s' "[{\"text\":\"${button_text[$x]}\"," \
								"\"url\":\"${button_url[$x]}\"}],")
						done
					fi
					printf '%s' "{\"inline_keyboard\":[$(sed -E 's/(.*)],/\1]/' <<< "${obj[@]}")]}"
				;;
			esac
		;;
		telegraph)
			GRAPHTOKEN=$(jshon -Q -e result -e access_token -u < "$basedir/telegraph_data")
			GRAPHAPI="https://api.telegra.ph"
			for x in $(seq 0 $j); do
				graph_content[$x]="{\"tag\":\"img\",\"attrs\":{\"src\":\"${graph_element[$x]}\"}},"
			done
			graph_content="[$(printf '%s' "${graph_content[*]}" | head -c -1)]"
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
		last_photo=$(($(jshon -Q -e photo -l <<< "$message") - 1))
		photo_id=$(jshon -Q -e photo -e $last_photo -e file_id -u <<< "$message")
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
		file_path=$(curl -s "${TELEAPI}/getFile" --form-string "file_id=$document_id" | jshon -Q -e result -e file_path -u)
		ext=$(sed 's/.*\.//' <<< "$file_path")
		case "$ext" in
			jpg|png|jpeg)
				file_type=photo
				photo_id=$document_id
			;;
			gif)
				file_type=animation
				animation_id=$document_id
			;;
			mp4)
				file_type=video
				video_id=$document_id
			;;
			mp3|ogg|flac|wav)
				file_type=audio
				audio_id=$document_id
			;;
			*)
				file_type=document
			;;
		esac
	elif [[ "$(jshon -Q -e new_chat_members <<< "$message")" != "" ]]; then
		new_members=$(jshon -Q -e new_chat_members <<< "$message")
		file_type="new_members"
	fi
}
get_normal_reply() {
	case $normal_message in
		"!start")
			text_id="this is a mksh bot, use !source to download"
			get_reply_id self
			tg_method send_message
			return 1
		;;
		"!start help"|"!help")
			if [[ "$fn_args" == "help" ]] || [[ "$fn_args" == "" ]]; then
				if [[ "$type" == "private" ]]; then
					set +f
					text_id=$(printf '%s\n' "$(cat help/* | grep -A 1 '^Usage' | grep -v '^Usage\|--' | sed 's/^  //' | sort)" "" 'send !help <command> for details')
					set -f
				else
					parse_mode=html
					markdown=('<a href="http://t.me/neekshellbot?start=help">' '</a>')
					text_id="command list"
				fi
			else
				text_id=$(cat help/"$fn_args")
				[[ "$text_id" = "" ]] && text_id="command not found"
			fi
			get_reply_id self
			tg_method send_message
			return 1
		;;
		"!source")
			source_id=$RANDOM
			zip -r source-"$source_id".zip neekshellbot.sh custom_commands LICENSE README.md webhook.php
			document_id="@source-$source_id.zip"
			get_reply_id self
			tg_method send_document upload
			rm source-"$source_id".zip
			text_id="https://gitlab.com/craftmallus/neekshell-telegrambot/"
			tg_method send_message
			return 1
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
			tg_method send_inline
		;;
	esac
}
get_button_reply() {
	case $callback_message_text in
		test)
			text_id="$callback_data"
			tg_method button_reply
			chat_id=$callback_user_id
			tg_method send_message
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
		if [[ "$type" == "private" ]]; then
			chat_title=$user_fname
		else
			chat_title=$(jshon -Q -e chat -e title -u <<< "$message")
		fi
		update_db
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
	if [[ $(grep -w -- "^$user_id\|^$inline_user_id\|^$callback_user_id" banned 2>/dev/null) ]]; then
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
					fn_arg=($fn_args)
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
		source tg_method.sh
		if [[ "$message" != "" ]]; then
			get_normal_reply
			[[ $? != 1 ]] && source custom_commands/normal_reply.sh
		elif [[ "$inline_message" != "" ]]; then
			get_inline_reply
			[[ $? != 1 ]] && source custom_commands/inline_reply.sh
		elif [[ "$callback_data" != "" ]]; then
			get_button_reply
			[[ $? != 1 ]] && source custom_commands/button_reply.sh
		fi
	fi
}
input=$1
basedir=$(realpath .)
tmpdir="/tmp/neekshell"
[[ ! -d $tmpdir ]] && mkdir $tmpdir
process_reply
END_TIME=$(bc <<< "$(date +%s%N) / 1000000")
[[ ! -d stats/ ]] && mkdir stats/
if [[ "$user_id" != "" ]]; then # usage in ms per user
	user_usage=$(grep -w -- "$(date +%y%m%d):$user_id" stats/users-usage)
	if [[ "$user_usage" == "" ]]; then
		printf '%s\n' "$(date +%y%m%d):$user_id:$(($END_TIME - $START_TIME))" >> stats/users-usage
	else
		sed -i "s/$user_usage/$(date +%y%m%d):$user_id:$(($(cut -f 3 -d ':' <<< "$user_usage")+($END_TIME - $START_TIME)))/" stats/users-usage
	fi
fi
if [[ "$chat_id" != "" ]]; then # usage in messages per chat
	chat_usage=$(grep -w -- "$(date +%y%m%d):$chat_id" stats/chats-usage)
	if [[ "$chat_usage" == "" ]]; then
		printf '%s\n' "$(date +%y%m%d):$chat_id:1" >> stats/chats-usage
	else
		sed -i "s/$chat_usage/$(date +%y%m%d):$chat_id:$(($(cut -f 3 -d ':' <<< "$chat_usage")+1))/" stats/chats-usage
	fi
fi
printf '%s\n' "[$(date "+%F %H:%M:%S")] elapsed time: $(($END_TIME - $START_TIME))ms"
