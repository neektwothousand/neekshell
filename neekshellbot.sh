#!/bin/mksh
set -f
START_TIME=$(bc <<< "$(date +%s%N) / 1000000")
PS4="[$(date "+%F %H:%M:%S")] "
exec 1>>"log.log" 2>&1
TOKEN=$(cat ./token)
TELEAPI="http://192.168.1.15:8081/bot${TOKEN}"
PATH="$HOME/.local/bin:$PATH"
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
				"type: $chat_type" > "$file_chat"
		else
			if [[ "title: $chat_title" != "$(grep -- "^title" "$file_chat")" ]]; then
				sed -i "s/^title: .*/title: $chat_title/" "$file_chat"
			fi
		fi
	fi
}
is_status() {
	s_file=$1
	if [[ -e "$s_file" ]]; then
		[[ ! "$user_id" ]] && user_id=null
		grep -w -- "^$user_id" "$s_file"
	fi
}
is_chat_admin() {
	for x in "$user_id" "$(jshon -Q -e result -e id -u < botinfo)"; do
		get_member_id=$x
		tg_method get_chat_member
		chat_admin=$(jshon -Q -e result -e status -u <<< "$curl_result" \
			| grep -w "creator\|administrator")
		if [[ ! "$chat_admin" ]]; then
			break
		fi
	done
	printf '%s' "$chat_admin"
}
loading() {
	case $1 in
		1)
			text_id="processing..."
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
	file_type=$(jshon -Q -k <<< "$message" \
		| grep -o "^text\|^sticker\|^animation\|^photo\|^video\|^audio\|^voice\|^document\|^new_chat_members")
	case "$file_type" in
		text)
			text_id=$(jshon -Q -e text -u <<< "$message")
			if [[ ! -e botinfo ]]; then
				tg_method get_me
				printf '%s\n' "$curl_result" > botinfo
			fi
			text_id=${text_id/@$(jshon -Q -e result -e username -u < botinfo)/}
		;;
		sticker)
			sticker_id=$(jshon -Q -e sticker -e file_id -u <<< "$message")
		;;
		animation)
			animation_id=$(jshon -Q -e animation -e file_id -u <<< "$message")
		;;
		photo)
			last_photo=$(($(jshon -Q -e photo -l <<< "$message") - 1))
			photo_id=$(jshon -Q -e photo -e $last_photo -e file_id -u <<< "$message")
		;;
		video)
			video_id=$(jshon -Q -e video -e file_id -u <<< "$message")
		;;
		audio)
			audio_id=$(jshon -Q -e audio -e file_id -u <<< "$message")
		;;
		voice)
			voice_id=$(jshon -Q -e voice -e file_id -u <<< "$message")
		;;
		document)
			document_id=$(jshon -Q -e document -e file_id -u <<< "$message")
			file_path=$(curl -s "${TELEAPI}/getFile" --form-string "file_id=$document_id" | jshon -Q -e result -e file_path -u)
			ext=$(sed 's/.*\.//' <<< "$file_path")
			case "$ext" in
				jpg|png|jpeg|JPG|PNG|JPEG)
					file_type=photo
					photo_id=$document_id
				;;
				gif|GIF)
					file_type=animation
					animation_id=$document_id
				;;
				mp4|webm|avi|mkv|MP4|WEBM|AVI|MKV)
					file_type=video
					video_id=$document_id
				;;
				mp3|ogg|flac|wav|MP3|OGG|FLAC|WAV)
					file_type=audio
					audio_id=$document_id
				;;
				*)
					file_type=document
				;;
			esac
		;;
		new_chat_members)
			new_members=$(jshon -Q -e new_chat_members <<< "$message")
		;;
	esac
}
get_message_user_info() {
	case "$2" in
		reply) x=1 ;;
		*) x=0 ;;
	esac
	case "$(grep -o "^sender_chat\|^from" <<< "${message_key[$x]}")" in
		from)
			user_id[$x]=$(jshon -Q -e from -e id -u <<< "$1")
			user_tag[$x]=$(jshon -Q -e from -e username -u <<< "$1")
			user_fname[$x]=$(jshon -Q -e from -e first_name -u <<< "$1")
			user_lname[$x]=$(jshon -Q -e from -e last_name -u <<< "$1")
		;;
		sender_chat)
			user_id[$x]=$(jshon -Q -e sender_chat -e id -u "$1")
			user_tag[$x]=$(jshon -Q -e sender_chat -e username -u <<< "$1")
			user_fname[$x]=$(jshon -Q -e sender_chat -e title -u <<< "$1")
		;;
	esac
}
get_normal_reply() {
	case "$command" in
		"!start")
			get_reply_id self
			case "${arg[0]}" in
				"")
					text_id="this is a mksh bot, use !source to download"
				;;
				"help"|"/start")
					if [[ "$chat_type" == "private" ]]; then
						set +f
						text_id=$(printf '%s\n' "$(cat help/* 2>/dev/null \
							| grep -A 1 '^Usage' | grep -v '^Usage\|--' | sed 's/^  //' | sort)" "" 'send !help <command> for details')
						set -f
					else
						parse_mode=html
						markdown=('<a href="http://t.me/neekshellbot?start=help">' '</a>')
						text_id="command list"
					fi
				;;
			esac
			if [[ "$text_id" ]]; then
				tg_method send_message
			fi
		;;
		"!help"|"!bahelp"|"!cahelp")
			get_reply_id self
			if [[ ! "${arg[0]}" ]]; then
				if [[ "$chat_type" == "private" ]]; then
					set +f
					case "$command" in
						"!help")
							help_list=$(cat help/* 2>/dev/null)
						;;
						"!bahelp")
							help_list=$(cat help/bot_admin/* 2>/dev/null)
						;;
						"!cahelp")
							help_list=$(cat help/chat_admin/* 2>/dev/null)
						;;
					esac
					set -f
					help_list=$(grep -A 1 '^Usage' <<< "$help_list" | grep -v '^Usage\|--' | sed 's/^  //' | sort)
					text_id=$(printf '%s\n' "$help_list" "" "send !help <command> for details")
					[[ "$command" == "!help" ]] && text_id=$(printf '%s\n' "$text_id" "!bahelp for bot admin" "!cahelp for chat admin")
				else
					parse_mode=html
					markdown=('<a href="http://t.me/neekshellbot?start=help">' '</a>')
					text_id="command list"
				fi
			else
				case "$command" in
					"!help")
						text_id=$(cat "help/${arg[0]}")
					;;
					"!bahelp")
						text_id=$(cat "help/bot_admin/${arg[0]}")
					;;
					"!cahelp")
						text_id=$(cat "help/chat_admin/${arg[0]}")
					;;
				esac
				[[ ! "$text_id" ]] && text_id="${arg[0]} not found"
			fi
			tg_method send_message
		;;
		"!source")
			source_id=$RANDOM
			zip -r source-"$source_id".zip \
				custom_commands help tools LICENSE \
				README.md getinput.sh neekshellbot.sh \
				tg_method.sh webhook.sh \
				-x custom_commands/user_generated/\*
			caption="https://gitlab.com/craftmallus/neekshell-telegrambot/"
			document_id="@source-$source_id.zip"
			get_reply_id self
			tg_method send_document upload
			rm source-"$source_id".zip
		;;
	esac
}
get_inline_reply() {
	case "$inline_message" in
		"ok")
			title="Ok"
			message_text="Ok"
			description="Alright"
			tg_method send_inline article
		;;
	esac
}
get_button_reply() {
	case "$callback_message_text" in
		test)
			text_id=$callback_data
			tg_method button_reply
			chat_id=$user_id
			tg_method send_message
		;;
	esac
}
process_reply() {
	keys=$(jshon -Q -k <<< "$input")
	update_type=$(grep -o "^message\|^channel_post\|^inline_query\|^callback_query" <<< "$keys")
	case "$update_type" in
		message|channel_post)
			case "$update_type" in
				message)
					message=$(jshon -Q -e message <<< "$input")
				;;
				channel_post)
					message=$(jshon -Q -e channel_post <<< "$input")
				;;
			esac
			message_key[0]=$(jshon -Q -k <<< "$message")
			jsp=($(jshon -Q \
				-e message_id -u -p \
				-e chat -e type -u -p \
					-e id -u <<< "$message"))
			message_id=${jsp[0]} chat_type=${jsp[1]} chat_id=${jsp[2]}
			get_message_user_info "$message"
			if [[ "$(grep -o "^reply_to_message" <<< "${message_key[0]}")" ]]; then
				message_key[1]=$(jshon -Q -k <<< "$message")
				reply_to_message=$(jshon -Q -e reply_to_message <<< "$message")
				reply_to_id=$(jshon -Q -e id -u <<< "$reply_to_message")
				get_message_user_info "$reply_to_message" reply
			fi
			if [[ "$chat_type" == "private" ]]; then
				chat_title=$user_fname
			else
				chat_title=$(jshon -Q -e chat -e title -u <<< "$message")
			fi
			update_db
			get_file_type
			if [[ "$file_type" != "text" ]]; then
				caption=$(jshon -Q -e caption -u <<< "$message")
			fi
		;;
		inline_query)
			inline=$(jshon -Q -e inline_query <<< "$input")
			message_key[0]=$(jshon -Q -k <<< "$inline")
			inline_id=$(jshon -Q -e id -u <<< "$inline")
			get_message_user_info "$inline"
			inline_message=$(jshon -Q -e query -u <<< "$inline")
			im_arg=$(cut -f 2- -d ' ' <<< "$inline_message")
		;;
		callback_query)
			callback=$(jshon -Q -e callback_query <<< "$input")
			message_key[0]=$(jshon -Q -k <<< "$callback")
			callback_id=$(jshon -Q -e id -u <<< "$callback")
			callback_data=$(jshon -Q -e data -u <<< "$callback")
			callback_caption=$(jshon -Q -e message -e caption -u <<< "$callback")
			callback_chat_id=$(jshon -Q -e message -e chat -e id -u <<< "$callback")
			callback_message_id=$(jshon -Q -e message -e message_id -u <<< "$callback")
			callback_message_text=$(jshon -Q -e message -e text -u <<< "$callback")
			get_message_user_info "$callback"
			message=$(jshon -Q -e message <<< "$callback")
			get_file_type
		;;
	esac
	if [[ $(is_status banned) ]]; then
		exit
	fi
	if [[ "$chat_type" == "private" ]] || [[ "$inline" ]] || [[ "$callback" ]]; then
		bot_chat_dir="db/bot_chats/"
		bot_chat_user_id=$user_id
	else
		bot_chat_dir="db/bot_group_chats/"
		bot_chat_user_id=$chat_id
	fi
	case "$file_type" in
		text)
			pf=$(head -n 1 <<< "$text_id" | grep -o '^.')
			case "$pf" in
				"/"|"$"|"&"|"%"|";"|"!")
					normal_message=$text_id
					command=$(head -n 1 <<< "$normal_message" | sed -e "s/ .*//" -e "s/^./!/")
				;;
				*)
					normal_message=$text_id
				;;
			esac

			unset text_id

			if [[ "$(grep "[^ ] [^ ]" <<< "$normal_message")" ]]; then
				if [[ "$command" ]]; then
					arg=($(sed "s/^\s*$command\s*//" <<< "$normal_message" \
						| tr '\n' ' ' | grep -oP "^([^\s]*\s*){10}"))
				fi
			else
				no_args=true
			fi
		;;
	esac
	source tg_method.sh
	case "$update_type" in
		message|channel_post)
			get_normal_reply
			[[ ! "$curl_result" ]] && source custom_commands/normal_reply.sh
		;;
		inline_query)
			get_inline_reply
			[[ ! "$curl_result" ]] && source custom_commands/inline_reply.sh
		;;
		callback_query)
			get_button_reply
			[[ ! "$curl_result" ]] && source custom_commands/button_reply.sh
		;;
	esac
}
input=$1
basedir=$(realpath .)
tmpdir="/tmp/neekshell"
[[ ! -d $tmpdir ]] && mkdir $tmpdir
process_reply
END_TIME=$(bc <<< "$(date +%s%N) / 1000000")
[[ ! -d stats/ ]] && mkdir stats/
if [[ "$chat_id" != "" ]]; then # usage in messages per chat
	chat_usage=$(grep -w -- "$(date +%y%m%d):$chat_id" stats/chats-usage)
	if [[ "$chat_usage" == "" ]]; then
		printf '%s\n' "$(date +%y%m%d):$chat_id:1" >> stats/chats-usage
	else
		sed -i "s/$chat_usage/$(date +%y%m%d):$chat_id:$(bc <<< "$(cut -f 3 -d ':' <<< "$chat_usage")+1")/" stats/chats-usage
	fi
fi
printf '%s\n' "[$(date "+%F %H:%M:%S")] elapsed time: $(bc <<< "$END_TIME - $START_TIME")ms"
