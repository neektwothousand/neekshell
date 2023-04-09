#!/bin/mksh
set -f

START_TIME=$(bc <<< "$(date +%s%N) / 1000000")

PS4="[$(date "+%F %H:%M:%S")] "
exec 1>>"log.log" 2>&1

TOKEN=$(cat ./token)
TELEAPI="http://192.168.1.15:8081/bot${TOKEN}"
PATH="$HOME/.local/bin:$PATH"

input=$1
basedir=$(realpath "$(dirname $0)")
tmpdir="/tmp/neekshell"
[[ ! -d $tmpdir ]] && mkdir $tmpdir

update_db_file() {
	for x in $(seq 0 $((${#value[@]}-1))); do
		grep_field=$(grep -- "^${field[$x]}" "$1")
		if [[ "${field[$x]}: ${value[$x]}" != "$grep_field" ]]; then
			sed -i -- "/^${field[$x]}: .*/d" "$1"
			printf '%s\n' "${field[$x]}: ${value[$x]}" >> "$1"
		fi
	done
}

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
			value=("$user_tag" "$user_fname" "$user_lname")
			field=("tag" "fname" "lname")
			update_db_file "$file_user"
		fi
	fi
	if [[ "${message[1]}" != "" ]]; then
		[[ ! -d db/users/ ]] && mkdir -p db/users/
		file_reply_user=db/users/"${user_id[1]}"
		if [[ ! -e "$file_reply_user" ]]; then
			printf '%s\n' \
				"tag: ${user_tag[1]}" \
				"id: ${user_id[1]}" \
				"fname: ${user_fname[1]}" \
				"lname: ${user_lname[1]}" > "$file_reply_user"
		fi
	fi
	if [[ "$chat_id" ]] && [[ "$chat_type" != "private" ]]; then
		[[ ! -d db/chats/ ]] && mkdir -p db/chats/
		file_chat=db/chats/"$chat_id"
		if [[ ! -e "$file_chat" ]]; then
			printf '%s\n' \
				"title: $chat_title" \
				"id: $chat_id" \
				"tag: $chat_tag" \
				"type: $chat_type" > "$file_chat"
		else
			value=("$chat_title" "$chat_tag")
			field=("title" "tag")
			update_db_file "$file_chat"
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
	case "$1" in
		bot_only)
			get_member_id=$(jshon -Q -e result -e id -u < botinfo)	
			tg_method get_chat_member
			chat_admin=$(jshon -Q -e result -e status -u <<< "$curl_result" \
				| grep -w "creator\|administrator")
		;;
		*)
			for x in "$user_id" "$(jshon -Q -e result -e id -u < botinfo)"; do
				get_member_id=$x
				tg_method get_chat_member
				chat_admin=$(jshon -Q -e result -e status -u <<< "$curl_result" \
					| grep -w "creator\|administrator")
				if [[ ! "$chat_admin" ]]; then
					break
				fi
			done
		;;
	esac
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
			if [[ "${message[1]}" != "" ]]; then
				reply_id=${message_id[1]}
			else
				reply_id=$message_id
			fi
		;;
		self)
			reply_id=$message_id
		;;
		reply)
			reply_id=${message_id[1]}
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
						text_id=$(
							printf '%s\n' \
								"$(cat help/* 2>/dev/null \
									| grep -A 1 '^Usage' \
									| grep -v '^Usage\|--' \
									| sed 's/^  //' | sort)" \
								"" \
								'send !help <command> for details'
						)
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
						file=$(tr -d "/." <<< "${arg[0]}")
						text_id=$(cat "help/$file")
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
get_message_info() {
	message_key[0]=$(jshon -Q -k <<< "$1")
	if [[ "$(grep "^reply_to_message" <<< "${message_key[0]}")" ]]; then
		x=1
		message[$x]=$(jshon -Q -e reply_to_message <<< "$1")
		message_key[$x]=$(jshon -Q -k <<< "${message[$x]}")
	else
		x=0
		message[$x]=$1
	fi
	for x in $(seq 0 $x); do
		file_type[$x]=$(jshon -Q -k <<< "${message[$x]}" \
			| grep -o "^text\|^sticker\|^animation\|^photo\|^video\|^audio\|^voice\|^document\|^new_chat_members" \
			| head -n 1)
		case "${file_type[$x]}" in
			text)
				user_text[$x]=$(jshon -Q -e text -u <<< "${message[$x]}")
				if [[ ! -e botinfo ]]; then
					tg_method get_me
					printf '%s\n' "$curl_result" > botinfo
				fi
				user_text[$x]=${user_text[$x]/@$(jshon -Q -e result -e username -u < botinfo)/}
			;;
			*)
				caption[$x]=$(jshon -Q -e caption -u <<< "${message[$x]}")
				case "${file_type[$x]}" in
					sticker)
						sticker_id[$x]=$(jshon -Q -e sticker -e file_id -u <<< "${message[$x]}")
						sticker_is_animated[$x]=$(jshon -Q -e sticker -e is_animated -u <<< "${message[$x]}")
						sticker_is_video[$x]=$(jshon -Q -e sticker -e is_video -u <<< "${message[$x]}")
					;;
					animation)
						animation_id[$x]=$(jshon -Q -e animation -e file_id -u <<< "${message[$x]}")
					;;
					photo)
						last_photo=$(($(jshon -Q -e photo -l <<< "${message[$x]}") - 1))
						photo_id[$x]=$(jshon -Q -e photo -e $last_photo -e file_id -u <<< "${message[$x]}")
					;;
					video)
						video_id[$x]=$(jshon -Q -e video -e file_id -u <<< "${message[$x]}")
					;;
					audio)
						audio_id[$x]=$(jshon -Q -e audio -e file_id -u <<< "${message[$x]}")
					;;
					voice)
						voice_id[$x]=$(jshon -Q -e voice -e file_id -u <<< "${message[$x]}")
					;;
					document)
						document_id[$x]=$(jshon -Q -e document -e file_id -u <<< "${message[$x]}")
						file_path[$x]=$(curl -s "${TELEAPI}/getFile" --form-string "file_id=${document_id[$x]}" | jshon -Q -e result -e file_path -u)
						ext[$x]=$(sed 's/.*\.//' <<< "${file_path[$x]}")
						case "${ext[$x]}" in
							jpg|png|jpeg|JPG|PNG|JPEG)
								file_type[$x]=photo
								photo_id[$x]=${document_id[$x]}
							;;
							gif|GIF)
								file_type[$x]=animation
								animation_id[$x]=${document_id[$x]}
							;;
							mp4|webm|avi|mkv|3gp|MP4|WEBM|AVI|MKV|3GP)
								file_type[$x]=video
								video_id[$x]=${document_id[$x]}
							;;
							mp3|ogg|oga|flac|wav|MP3|OGG|OGA|FLAC|WAV)
								file_type[$x]=audio
								audio_id[$x]=${document_id[$x]}
							;;
							*)
								file_type[$x]=document
							;;
						esac
					;;
					new_chat_members)
						new_members[$x]=$(jshon -Q -e new_chat_members <<< "${message[$x]}")
					;;
				esac
		esac
		
		jsp=$(jshon -Q \
			-e message_id -u -p \
			-e chat -e type -u -p \
				-e id -u -p \
				-e title -u -p \
				-e username -u <<< "${message[$x]}")
		message_id[$x]=$(sed -n 1p <<< "$jsp") \
		chat_type[$x]=$(sed -n 2p <<< "$jsp") \
		chat_id[$x]=$(sed -n 3p <<< "$jsp") \
		chat_title[$x]=$(sed -n 4p <<< "$jsp") \
		chat_tag[$x]=$(sed -n 5p <<< "$jsp")
		case "$(grep -o "^sender_chat\|^from" <<< "${message_key[$x]}")" in
			from)
				jsp=$(jshon -Q -e from \
					-e id -u -p \
					-e first_name -u -p \
					-e username -u -p \
					-e last_name -u -p \
					-e is_premium -u <<< "${message[$x]}")
				user_id[$x]=$(sed -n 1p <<< "$jsp") user_fname[$x]=$(sed -n 2p <<< "$jsp") \
				user_tag[$x]=$(sed -n 3p <<< "$jsp") user_lname[$x]=$(sed -n 4p <<< "$jsp")
				is_premium[$x]=$(jshon -Q -e from -e is_premium -u <<< "${message[$x]}")
			;;
			sender_chat)
				jsp=$(jshon -Q -e sender_chat \
					-e id -u -p \
					-e title -u -p \
					-e username -u <<< "${message[$x]}")
				sender_chat_id[$x]=$(sed -n 1p <<< "$jsp") \
				sender_chat_title[$x]=$(sed -n 2p <<< "$jsp") \
				sender_chat_tag[$x]=$(sed -n 3p <<< "$jsp")
			;;
		esac
	done
}
process_reply() {
	keys=$(jshon -Q -k <<< "$input") x=0
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
			get_message_info "$message"
		;;
		inline_query)
			inline=$(jshon -Q -e inline_query <<< "$input")
			message_key=$(jshon -Q -k <<< "$inline")
			inline_id=$(jshon -Q -e id -u <<< "$inline")
			inline_message=$(jshon -Q -e query -u <<< "$inline")
			im_arg=$(cut -f 2- -d ' ' <<< "$inline_message")
			get_message_info "$inline"
		;;
		callback_query)
			callback=$(jshon -Q -e callback_query <<< "$input")
			message_key=$(jshon -Q -k <<< "$callback")
			jsp=$(jshon -Q -e id -u -p \
				-e message -e chat -e id -u -p -p -p \
				-e message -e message_id -u <<< "$callback")
			callback_id=$(sed -n 1p <<< "$jsp") \
			callback_chat_id=$(sed -n 2p <<< "$jsp") \
			callback_message_id=$(sed -n 3p <<< "$jsp")
			callback_data=$(jshon -Q -e data -u <<< "$callback")
			callback_caption=$(jshon -Q -e message -e caption -u <<< "$callback")
			callback_message_text=$(jshon -Q -e message -e text -u <<< "$callback")
			message=$(jshon -Q -e message <<< "$callback")
			get_message_info "$callback"
		;;
	esac
	[[ $(is_status banned) ]] && exit
	update_db
	if [[ "$chat_type" == "private" ]] || [[ "$inline" ]] || [[ "$callback" ]]; then
		bot_chat_dir="db/bot_chats/"
		bot_chat_user_id=$user_id
	else
		bot_chat_dir="db/bot_group_chats/"
		bot_chat_user_id=$chat_id
	fi
	case "$file_type" in
		text)
			pf=$(head -n 1 <<< "$user_text" | grep -o '^.')
			case "$pf" in
				"/"|"$"|"&"|"%"|";"|"!")
					command=$(head -n 1 <<< "$user_text" | sed -e "s/ .*//" -e "s/^./!/")
				;;
			esac

			if [[ "$(grep "[^ ] [^ ]" <<< "$user_text")" ]]; then
				if [[ "$command" ]]; then
					arg=($(sed "s/^\s*.$(tail -c +2 <<< "$command")\s*//" <<< "$user_text" \
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
process_reply

[[ ! -d stats/ ]] && mkdir stats/
if [[ "$chat_id" != "" ]]; then # usage in messages per chat
	chat_usage=$(grep -w -- "$(date +%y%m%d):$chat_id" stats/chats-usage)
	if [[ "$chat_usage" == "" ]]; then
		printf '%s\n' "$(date +%y%m%d):$chat_id:1" >> stats/chats-usage
	else
		sed -i "s/$chat_usage/$(date +%y%m%d):$chat_id:$(bc <<< "$(cut -f 3 -d ':' <<< "$chat_usage")+1")/" stats/chats-usage
	fi
fi

END_TIME=$(bc <<< "$(date +%s%N) / 1000000")
printf '%s\n' "[$(date "+%F %H:%M:%S")] elapsed time: $(bc <<< "$END_TIME - $START_TIME")ms"
