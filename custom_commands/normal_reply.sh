case $normal_message in
	"!top+")
		list_rep=$(grep -r "rep: " db/users/ | cut -d : -f 1)
		for x in $(seq $(wc -l <<< "$list_rep")); do
			user_file[$x]=$(sed -n ${x}p <<< "$list_rep")
			user_rep[$x]=$(sed -e 1,2d "${user_file[$x]}" | sed -e 's/fname: //' -e 's/lname: //' -e 's/rep: //' | tr '\n' ' ' | sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g' | sed -e "s|(.*)\s(.*)\s|\2 ☆ <b>\1</b>|")
		done
		if [ "${user_rep[*]}" = "" ]; then
			text_id="oops, respect not found"
		else
			enable_markdown=true
			text_id=$(sort -nr <<< "$(printf '%s\n' "${user_rep[@]}")" | head -n 10)
		fi
		get_reply_id self
		tg_method send_message > /dev/null
	;;
	"!my+")
		user_rep=$(sed -e 1,2d "$file_user" | sed -e 's/fname: //' -e 's/lname: //' -e 's/rep: //' | tr '\n' ' ' | sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g' | sed -e "s|(.*)\s(.*)\s|\2 ☆ <b>\1</b>|")
		if [ "$user_rep" = "" ]; then
			text_id="oops, respect not found"
		else
			enable_markdown=true
			text_id=$user_rep
		fi
		get_reply_id self
		tg_method send_message > /dev/null
	;;
	"!me "*)
		text_id="> $username_fname $fn_arg"
		tg_method send_message > /dev/null
		to_delete_id=$message_id
		tg_method delete_message > /dev/null
	;;
	"!fortune")
		text_id=$(/usr/bin/fortune fortunes paradoxum goedel linuxcookie | tr '\n' ' ' | awk '{$2=$2};1')
		get_reply_id any
		tg_method send_message > /dev/null
	;;
	"!decode")
		update_id="${message_id}${username_id}"
		printf '%s' "$input" | sed -e 's/{"/{\n"/g' -e 's/,"/,\n"/g' > decode-$update_id.json
		document_id=@decode-$update_id.json
		get_reply_id any
		tg_method send_document upload > /dev/null
		rm decode-$update_id.json
	;;
	"!ping")
		text_id=$(printf '%s\n' "pong" ; ping -c 1 api.telegram.org | grep time= | sed 's/.*time=//')
		get_reply_id self
		tg_method send_message > /dev/null
	;;
	"!d"[0-9]*|"!d"[0-9]*"*"[0-9]*)
		if [ "$(grep "*" <<< "$normal_message")" != "" ]; then
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
		get_reply_id self
		tg_method send_message > /dev/null
	;;
	"!gayscale"|"!gs")
		if [ "$reply_to_user_id" = "" ]; then
			gs_id=$username_id
		else
			gs_id=$reply_to_user_id
		fi
		[ ! -d .lock+/gs/ ] && mkdir -p .lock+/gs/
		lockfile=.lock+/gs/"$gs_id"-lock
		# check if it's younger than one day
		lock_age=$(bc <<< "$(date +%s) - $(stat -c "%W" $lockfile)")
		if [ -e $lockfile ] && [ $lock_age -lt 86400 ]; then
			text_id=$(cat $lockfile)
		else
			rm $lockfile
			get_chat_id=$gs_id
			gs_info="$username_fname $username_lname $(tg_method get_chat | jshon -Q -e result -e bio -u)"
			if [ "$(grep 'admin\|bi\|gay\|🏳️‍🌈' <<< "$gs_info")" != "" ]; then
				gs_perc=$(((RANDOM % 51) + 50))
			else
				gs_perc=$((RANDOM % 101))
			fi
			if [ $gs_perc -gt 9 ]; then
				for x in $(seq $((gs_perc/10))); do
					rainbow="🏳️‍🌈${rainbow}"
				done
			fi
			if [ "$reply_to_message" != "" ]; then
				gs_fname=$reply_to_user_fname
			else
				gs_fname=$username_fname
			fi
			text_id="$gs_fname is ${gs_perc}% gay $rainbow"
			printf '%s' "$text_id" > $lockfile
		fi
		get_reply_id any
		tg_method send_message > /dev/null
	;;
	"!wenit "*|"!witen "*)
		trad=$(sed -e 's/!w//' -e 's/\s.*//' <<< "$normal_message")
		search=$(sed 's/\s/%20/g' <<< "$fn_arg")
		wordreference=$(curl -A 'neekshellbot/1.0' -s "https://www.wordreference.com/$trad/$search" \
			| sed -En "s/.*\s>(.*\s)<em.*/\1/p" \
			| sed -e "s/<a.*//g" -e "s/<span.*'\(.*\)'.*/\1/g" \
			| head | awk '!x[$0]++')
		if [ "$wordreference" != "" ]; then
			text_id=$(printf '%s\n' "translations:" "$wordreference")
		else
			text_id=$(printf '%s' "$search " "not found" | sed 's/%20/ /g')
		fi
		get_reply_id self
		tg_method send_message > /dev/null
	;;
	"!reddit "*)
		get_reply_id self
		r_subreddit "$fn_arg"
	;;
	"!jpg")
		request_id=$RANDOM
		get_reply_id reply
		get_file_type reply
		case $file_type in
			text|"")
				text_id="reply to a media"
				tg_method send_message > /dev/null
			;;
			photo|document)
				case $file_type in
					photo)
						media_id=$photo_id
					;;
					document)
						media_id=$document_id
					;;
				esac
				file_path=$(curl -s "${TELEAPI}/getFile" --form-string "file_id=$media_id" | jshon -Q -e result -e file_path -u)
				ext=$(grep -o "...$" <<< "$file_path")
				case "$ext" in
					png)
						wget -O "pic-$request_id-r.$ext" "https://api.telegram.org/file/bot$TOKEN/$file_path"
						convert "pic-$request_id-r.$ext" "pic-$request_id-r.jpg"
						rm "pic-$request_id-r.$ext"
					;;
					jpg)
						wget -O "pic-$request_id-r.$ext" "https://api.telegram.org/file/bot$TOKEN/$file_path"
					;;
					*) return ;;
				esac
				magick "pic-$request_id-r.jpg" -resize 400% "pic-$request_id.jpg"
				magick "pic-$request_id.jpg" -quality 7 "pic-low-$request_id.jpg"
				
				photo_id="@pic-low-$request_id.jpg"
				tg_method send_photo upload > /dev/null
				
				rm "pic-$request_id.jpg" \
					"pic-low-$request_id.jpg" \
					"pic-$request_id-r.jpg"
			;;
			sticker)
				file_path=$(curl -s "${TELEAPI}/getFile" --form-string "file_id=$sticker_id" | jshon -Q -e result -e file_path -u)
				wget -O "sticker-$request_id-0.webp" "https://api.telegram.org/file/bot$TOKEN/$file_path"
				convert "sticker-$request_id-0.webp" "sticker-$request_id-1.jpg"
				magick "sticker-$request_id-1.jpg" -resize 200% "sticker-$request_id-2.jpg"
				magick "sticker-$request_id-2.jpg" -quality 10 "sticker-$request_id-3.jpg"
				magick "sticker-$request_id-3.jpg" -resize 512x512 "sticker-$request_id-4.jpg"
				convert "sticker-$request_id-4.jpg" "sticker-$request_id-5.webp"
				
				sticker_id="@sticker-$request_id-5.webp"
				tg_method send_sticker upload > /dev/null
				
				rm "sticker-$request_id-0.webp" \
					"sticker-$request_id-1.jpg" \
					"sticker-$request_id-2.jpg" \
					"sticker-$request_id-3.jpg" \
					"sticker-$request_id-4.jpg" \
					"sticker-$request_id-5.webp"
			;;
			animation)
				file_path=$(curl -s "${TELEAPI}/getFile" --form-string "file_id=$animation_id" | jshon -Q -e result -e file_path -u)
				wget -O animation-"$request_id".mp4 "https://api.telegram.org/file/bot$TOKEN/$file_path"
				
					loading 1
				
				ffmpeg -i animation-"$request_id".mp4 -crf 50 -an animation-low-"$request_id".mp4
				
					loading 2
				
				animation_id="@animation-low-$request_id.mp4"
				tg_method send_animation upload > /dev/null
				
					loading 3
				
				rm animation-"$request_id".mp4 animation-low-"$request_id".mp4
			;;
			video)
				file_path=$(curl -s "${TELEAPI}/getFile" --form-string "file_id=$video_id" | jshon -Q -e result -e file_path -u)
				wget -O video-"$request_id".mp4 "https://api.telegram.org/file/bot$TOKEN/$file_path"
				
					loading 1
				
				ffmpeg -i video-"$request_id".mp4 -crf 50 video-low-"$request_id".mp4
				
					loading 2
				
				video_id="@video-low-$request_id.mp4"
				tg_method send_video upload > /dev/null
				
					loading 3
				
				rm video-"$request_id".mp4 video-low-"$request_id".mp4
			;;
			audio)
				file_path=$(curl -s "${TELEAPI}/getFile" --form-string "file_id=$audio_id" | jshon -Q -e result -e file_path -u)
				wget -O audio-"$request_id".mp3 "https://api.telegram.org/file/bot$TOKEN/$file_path"
				
					loading 1
				
				ffmpeg -i audio-"$request_id".mp3 -vn -acodec libmp3lame -b:a 6k audio-low-"$request_id".mp3
				
					loading 2
				
				audio_id="@audio-low-$request_id.mp3"
				tg_method send_audio upload > /dev/null
				
					loading 3
				
				rm audio-"$request_id".mp3 audio-low-"$request_id".mp3
			;;
			voice)
				file_path=$(curl -s "${TELEAPI}/getFile" --form-string "file_id=$voice_id" | jshon -Q -e result -e file_path -u)
				wget -O voice-"$request_id".ogg "https://api.telegram.org/file/bot$TOKEN/$file_path"
				
					loading 1
				
				ffmpeg -i voice-"$request_id".ogg -vn -acodec opus -b:a 6k -strict -2 voice-low-"$request_id".ogg
				
					loading 2
				
				voice_id="@voice-low-$request_id.ogg"
				tg_method send_voice upload > /dev/null
				
					loading 3
				
				rm voice-"$request_id".ogg voice-low-"$request_id".ogg
			;;
		esac
	;;
	"!hf")
		randweb=$(( ( RANDOM % 3 ) ))
		get_reply_id self
		case $randweb in
			0)
				popfeat=$(wget -q -O- "https://www.hentai-foundry.com/pictures/random/?enterAgree=1" | \
					grep -io '<div class="thumbTitle"><a href=['"'"'"][^"'"'"']*['"'"'"]' | \
					sed -e 's/^<div class="thumbTitle"><a href=["'"'"']//i' -e 's/["'"'"']$//i')
				hflist=$(sort -t / -k 5 <<< "$popfeat")
				counth=$(wc -l <<< "$hflist")
				randh=$(sed -n "$(( ( RANDOM % counth ) + 1 ))p" <<< "$hflist")
				wgethf=$(wget -q -O- "https://www.hentai-foundry.com$randh/?enterAgree=1")
				photo_id=$(sed -n 's/.*src="\([^"]*\)".*/\1/p' <<< "$wgethf" | \
					grep "pictures.hentai" | \
					sed "s/^/https:/")
				caption="https://www.hentai-foundry.com$randh"
				tg_method send_photo > /dev/null
			;;
			1)
				randh=$(wget -q -O- 'https://rule34.xxx/index.php?page=post&s=random')
				
				photo_id=$(grep 'content="https://img.rule34.xxx\|content="https://himg.rule34.xxx' <<< "$randh" \
					| sed -En 's/.*content="(.*)"\s.*/\1/p')
				caption="https://rule34.xxx/index.php?page=post&s=view&$(grep 'action="index.php?' <<< "$randh" \
					| sed -En 's/.*(id=.*)&.*/\1/p')"
				tg_method send_photo > /dev/null
			;;
			2)
				randh=$(wget -q -O- 'https://safebooru.org/index.php?page=post&s=random')
				
				photo_id=$(grep 'content="https://safebooru.org' <<< "$randh" \
					| sed -En 's/.*content="(.*)"\s.*/\1/p')
				caption="https://safebooru.org/index.php?page=post&s=view&$(grep 'action="index.php?' <<< "$randh" \
					| sed -En 's/.*(id=.*)&.*/\1/p')"
				tg_method send_photo > /dev/null
			;;
		esac
	;;
	"!deemix "*|"!deemix")
		if [ "$reply_to_text" != "" ]; then
			deemix_link=$(grep -o 'https://www.deezer.*\|https://deezer.*' <<< "$reply_to_text" | cut -f 1 -d ' ')
		else
			deemix_link=$fn_arg
		fi
		
		[ "$deemix_link" = "" ] && return
		
		if [ "$(grep 'track' <<< "$deemix_link")" = "" ]; then
			exit
		fi
		
		deemix_id=$RANDOM
		
			loading 1
		
		export LC_ALL=C.UTF-8
		export LANG=C.UTF-8
		
		song_title=$(/usr/local/bin/deemix -p ./ "$deemix_link" 2>&1 | tail -n 4 | sed -n 1p)
		song_file="$(basename -s .mp3 -- "$song_title")-$deemix_id.mp3"
		mv -- "$song_title" "$song_file"
		
		if [ "$(du -m -- "$song_file" | cut -f 1)" -ge 50 ]; then
			loading error
			rm -- "$song_file"
			text_id="file size exceeded"
			tg_method send_message > /dev/null
			return
		fi
		
			loading 2
		
		audio_id="@$song_file"
		get_reply_id any
		tg_method send_audio upload > /dev/null
		
			loading 3
		
		rm -- "$song_file"
	;;
	"!chat "*)
		if [ "$type" = "private" ] || [ $(is_admin) ] ; then
			chat_command=$fn_arg
			action=$(cut -d ' ' -f 1 <<< "$chat_command")
			get_reply_id self
			case $action in
				"create")
					[ ! -d $bot_chat_dir ] && mkdir -p $bot_chat_dir
					if [ "$(dir $bot_chat_dir | grep -o -- "$bot_chat_user_id")" = "" ]; then
						file_bot_chat="$bot_chat_dir$bot_chat_user_id"
						[ ! -e "$file_bot_chat" ] && printf '%s\n' "users: " > "$file_bot_chat"
						text_id="your chat id: \"$bot_chat_user_id\""
					else
						text_id="you've already an existing chat"
					fi
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
				;;
				"join")
					if [ "$(grep -r -- "$bot_chat_user_id" "$bot_chat_dir")" = "" ] \
					&& [ "$type" = "private" ]; then
						text_id="Select chat to join:"
						num_bot_chat=$(ls -1 "$bot_chat_dir" | wc -l)
						list_bot_chat=$(ls -1 "$bot_chat_dir")
						for j in $(seq 0 $((num_bot_chat - 1))); do
							button_text[$j]=$(sed -n $((j+1))p <<< "$list_bot_chat")
						done
						markup_id=$(inline_array button)
					elif [ "$(grep -r -- "$bot_chat_user_id" "$bot_chat_dir")" = "" ] \
					&& [ "$type" != "private" ];then
						if [ $(is_admin) ]; then
							join_chat=$(cut -d ' ' -f 2 <<< "$chat_command")
							sed -i "s/\(users: \)/\1$chat_id /" $bot_chat_dir"$join_chat"
							text_id="joined $join_chat"
						else
							markdown=("<code>" "</code>")
							text_id="Access denied"
							tg_method send_message > /dev/null
							return	
						fi
					else
						text_id="you're already in an existing chat"
					fi
				;;
				"leave")
					if [ "$(grep -r -- "$bot_chat_user_id" "$bot_chat_dir")" != "" ] \
					&& [ "$type" = "private" ]; then
						text_id="Select chat to leave:"
						num_bot_chat=$(ls -1 "$bot_chat_dir" | wc -l)
						list_bot_chat=$(ls -1 "$bot_chat_dir")
						for j in $(seq 0 $((num_bot_chat - 1))); do
							button_text[$j]=$(sed -n $((j+1))p <<< "$list_bot_chat")
						done
						markup_id=$(inline_array button)
					elif [ "$(grep -r -- "$bot_chat_user_id" "$bot_chat_dir")" != "" ] \
					&& [ "$type" != "private" ];then
						if [ $(is_admin) ]; then
							leave_chat=$(cut -d ' ' -f 2 <<< "$chat_command")
							sed -i "s/$chat_id //" $bot_chat_dir"$leave_chat"
							text_id="$leave_chat is no more"
						else
							markdown=("<code>" "</code>")
							text_id="Access denied"
							tg_method send_message > /dev/null
							return
						fi
					else
						text_id="you are not in an any chat yet"
					fi
				;;
				"users")
					if [ "$(grep -r -- "$bot_chat_user_id" "$bot_chat_dir")" != "" ]; then
						text_id="number of active users: $(grep -r -- "$bot_chat_user_id" $bot_chat_dir | sed 's/.*:\s//' | tr ' ' '\n' | sed '/^$/d' | wc -l)"
					else
						text_id="you are not in an any chat yet"
					fi
				;;
				"list")
					text_id="$(
						for c in $(seq "$(ls -1 "$bot_chat_dir" | wc -l)"); do
							bot_chat_id=$(ls -1 "$bot_chat_dir" | sed -n "${c}"p)
							bot_chat_users=$(sed 's/.*:\s//' "$bot_chat_dir$bot_chat_id" | tr ' ' '\n' | sed '/^$/d' | wc -l)
							printf '%s' "chat: $bot_chat_id users: $bot_chat_users"
						done
					)"
					[ "$text_id" = "" ] && text_id="no chats found"
				;;
				*)
					return
				;;
			esac
			tg_method send_message > /dev/null
		fi
	;;
	"!tag"|"!tag "*)
		if [ "$reply_to_text" = "" ]; then
			text_id=$(cut -f 2- -d ' ' <<< "$fn_arg")
		else
			text_id=$reply_to_text
		fi
		username=$(cut -f 1 -d ' ' <<< "$fn_arg")
		userid=$(sed -n 2p $(grep -r -- "$(sed 's/@//' <<< "$username")" db/users/ | cut -d : -f 1) | sed 's/id: //')
		if [ "$userid" != "" ] && [ "$text_id" != "" ]; then
			markdown=("<a href=\"tg://user?id=$userid\">" "</a>")
		elif [ "$userid" = "" ]; then
			text_id="$username not found"
		elif [ "$text_id" = "" ]; then
			text_id="text not found"
		fi
		tg_method send_message > /dev/null
	;;
	"!text2img"|"!text2img "*)
		if [ "$reply_to_text" != "" ]; then
			text2img=$reply_to_text
		else
			text2img=$fn_arg
		fi
		api_key=$(cat deepai_key)
		photo_id=$(curl -s "https://api.deepai.org/api/text2img" \
			-F "text=$text2img" \
			-H "api-key:$api_key" | jshon -e output_url -u)
		get_reply_id self
		tg_method send_photo > /dev/null
	;;
	"!owoifer"|"!owo"|"!cringe")
		reply=$(jshon -Q -e reply_to_message -e text -u <<< "$message")
		if [ "$reply" != "" ]; then
			numberspace=$(tr -dc ' ' <<< "$reply" | wc -c)
			
			[ "$numberspace" = "" ] && return
			
			case $normal_message in
				"!cringe")
					owoarray=("🥵" "🙈" "🤣" "😘" "🥺" "💁‍♀️" "OwO" "😳" "🤠" "🤪" "😜" "🤬" "🤧" "🦹‍♂" "🍌" "😏" "😒" "😎" "🙄" "🧐" "😈" "👐🏻" "👏🏻" "👀" "👅" "🍆" "🤢" "🤮" "🤡" "💯" "👌" "😂" "🅱️" "💦")
				;;
				"!owoifer"|"!owoifier"|"!owo")
					owoarray=("owo" "ewe" "uwu" ":3" "x3")
				;;
			esac
			
			for x in $(seq $(((numberspace / 8)+1))); do
				reply=$(sed "s/\s/\n/$(((RANDOM % numberspace)+1))" <<< "$reply")
			done
			
			for x in $(seq $(($(wc -l <<< "$reply") - 1))); do
				fixed_part[$x]=$(sed -n "${x}"p <<< "$reply" | sed "s/$/ ${owoarray[$((RANDOM % ${#owoarray[@]}))]} /")
			done
			
			fixed_text=$(printf '%s' "${fixed_part[*]}" "$(tail -1 <<< "$reply")" | tr -s ' ')
			
			text_id=$(sed -e 's/[lr]/w/g' -e 's/[LR]/W/g' <<< "$fixed_text")
			get_reply_id reply
		else
			text_id="reply to a text message"
			get_reply_id self
		fi
		if [ "$reply_to_user_id" = "$(jshon -Q -e result -e id -u < botinfo)" ]; then
			to_edit_id=$reply_to_id
			edit_text=$text_id
			tg_method edit_message > /dev/null
		else
			tg_method send_message > /dev/null
		fi
	;;
	"!sed "*)
		reply_to_caption=$(jshon -Q -e caption -u <<< "$reply_to_message")
		[ "$reply_to_caption" != "" ] && reply_to_text=$reply_to_caption
		if [ "$reply_to_text" != "" ]; then
			regex=$fn_arg
			case "$regex" in 
				"$(grep /g$ <<< "$regex")")
					regex=$(sed 's|/g$||' <<< "$regex")
					sed=$(sed -e "s/$regex/g" <<< "$reply_to_text")
				;; 
				*) 
					sed=$(sed -e "s/$regex/" <<< "$reply_to_text")
				;;
			esac
			text_id=$(printf '%s\n' "$sed" "FTFY")
		else
			text_id="reply to a text message"
		fi
		get_reply_id reply
		tg_method send_message > /dev/null
	;;
	"!neofetch")
		text_id=$(neofetch --stdout)
		markdown=("<code>" "</code>")
		get_reply_id self
		tg_method send_message > /dev/null
	;;
	"!stats")
		text_id=$(printf '%s\n' \
			"users: $(wc -l <<< $(ls -1 db/users/))" \
			"groups: $(wc -l <<< $(ls -1 db/chats/))")
		get_reply_id self
		tg_method send_message > /dev/null
	;;
	
	## administrative commands
	
	"!setadmin "*)
		if [ $(is_admin) ]; then
			username=$(tr -d '@' <<< "$fn_arg")
			setadmin_id=$(cat -- "$(grep -r -- "$username" db/users/ \
				| cut -d : -f 1 | sed -n 1p)" | sed -n 2p | sed 's/id: //')
			admin_check=$(grep -v "#" admins | grep -w -- "$setadmin_id")
			if [ -z "$setadmin_id" ]; then
				text_id="user not found"
			elif [ "$admin_check" != "" ]; then
				text_id="$username already admin"
			else
				printf '%s\n' "# $username\n$setadmin_id" >> admins
				text_id="admin $username set!"
			fi
		else
			markdown=("<code>" "</code>")
			text_id="Access denied"
		fi
		get_reply_id self
		tg_method send_message > /dev/null
	;;
	"!deladmin "*)
		if [ $(is_admin) ]; then
			username=$(tr -d '@' <<< "$fn_arg")
			deladmin_id=$(cat -- "$(grep -r -- "$username" db/users/ \
				| cut -d : -f 1 | sed -n 1p)" | sed -n 2p | sed 's/id: //')
			admin_check=$(grep -v "#" admins | grep -w -- "$deladmin_id")
			if [ -z "$deladmin_id" ]; then
				text_id="user not found"
			elif [ "$admin_check" != "" ]; then
				sed -i "/$username/d" admins
				sed -i "/$deladmin_id/d" admins
				text_id="$username is no longer admin"
			else
				text_id="$username is not admin"
			fi
		else
			markdown=("<code>" "</code>")
			text_id="Access denied"
		fi
		get_reply_id self
		tg_method send_message > /dev/null
	;;
	"!bin "*)
		markdown=("<code>" "</code>")
		if [ $(is_admin) ]; then
			command=$fn_arg
			text_id=$(mksh -c "$command" 2>&1)
			if [ "$text_id" = "" ]; then
				text_id="[no output]"
			fi
		else
			text_id="Access denied"
		fi
		get_reply_id self
		tg_method send_message > /dev/null
	;;
	"!ytdl "*|"!ytdl")
		get_reply_id self
		if [ $(is_admin) ]; then
			if [ "$reply_to_text" != "" ]; then
				ytdl_link=$(sed -e 's/.*(https.*)\s.*/\1/' <<< "$reply_to_text" | cut -d ' ' -f 1 | grep 'youtube\|youtu.be')
			else
				ytdl_link=$fn_arg
				[ "$ytdl_link" = "" ] && return
			fi
			ytdl_id=$RANDOM
			
				loading 1
			
			caption=$(youtube-dl --print-json --format mp4 -o ytdl-$ytdl_id.mp4 "$ytdl_link" | jshon -Q -e title -u)
			
			if [ "$(du -m ytdl-$ytdl_id.mp4 | cut -f 1)" -ge 50 ]; then
				loading error
				rm ytdl-$ytdl_id.mp4
				text_id="file size exceeded"
				tg_method send_message > /dev/null
				return
			fi
			
			ffmpeg -i ytdl-$ytdl_id.mp4 -ss 05 -frames:v 1 thumb-$ytdl_id.jpg
			video_id="@ytdl-$ytdl_id.mp4" thumb="@thumb-$ytdl_id.jpg"
			
				loading 2
			
			tg_method send_video upload > /dev/null
			
				loading 3
			
			rm "ytdl-$ytdl_id.mp4" "thumb-$ytdl_id.jpg"
		else
			markdown=("<code>" "</code>")
			text_id="Access denied"
			tg_method send_message > /dev/null
		fi
	;;
	"!nh "*)
		get_reply_id self
		if [ $(is_admin) ]; then
			nhentai_id=$(cut -d / -f 5 <<< "$fn_arg")
			nhentai_check=$(wget -q -O- "https://nhentai.net/g/$nhentai_id/1/")
			if [ "$nhentai_check" != "" ]; then
				h_delay=0.5 maxpages=10 p_offset=1
				numpages=$(grep 'num-pages' <<< "$nhentai_check" \
					| sed -e 's/.*<span class="num-pages">//' -e 's/<.*//')
				if [ "$numpages" -le "$maxpages" ]; then
					for j in $(seq 0 $((numpages - 1))); do
						media[$j]=$(wget -q -O- "https://nhentai.net/g/$nhentai_id/$p_offset/" \
							| grep 'img src' \
							| sed -e 's/.*<img src="//' -e 's/".*//')
						sleep $h_delay
						p_offset=$((p_offset + 1))
					done
					mediagroup_id=$(photo_array)
					tg_method send_mediagroup > /dev/null
				else
					for p in $(seq $((numpages/maxpages))); do
						for j in $(seq 0 $((maxpages - 1))); do
							media[$j]=$(wget -q -O- "https://nhentai.net/g/$nhentai_id/$p_offset/" \
								| grep 'img src' \
								| sed -e 's/.*<img src="//' -e 's/".*//')
							sleep $h_delay
							p_offset=$((p_offset + 1))
						done
						mediagroup_id=$(photo_array)
						tg_method send_mediagroup > /dev/null
					done
					for j in $(seq 0 $(((numpages - ${p}0) - 1))); do
						media[$j]=$(wget -q -O- "https://nhentai.net/g/$nhentai_id/$p_offset/" \
							| grep 'img src' \
							| sed -e 's/.*<img src="//' -e 's/".*//')
						sleep $h_delay
						p_offset=$((p_offset + 1))
					done
					mediagroup_id=$(photo_array)
					tg_method send_mediagroup > /dev/null
				fi
			else
				text_id="invalid id"
				tg_method send_message > /dev/null
			fi
		else
			markdown=("<code>" "</code>")
			text_id="Access denied"
		fi
		tg_method send_message > /dev/null
	;;
	"!nhzip "*)
		get_reply_id self
		if [ $(is_admin) ]; then
			nhentai_id=$(cut -d / -f 5 <<< "$fn_arg")
			nhentai_check=$(wget -q -O- "https://nhentai.net/g/$nhentai_id/1/")
			if [ "$nhentai_check" != "" ]; then
				maxpages=200
				numpages=$(grep 'num-pages' <<< "$nhentai_check" \
					| sed -e 's/.*<span class="num-pages">//' -e 's/<.*//')
				if [ "$numpages" -le "$maxpages" ]; then
					
						loading 1
					
					nhzip_id=$RANDOM
					nhentai_title=$(wget -q -O- "https://nhentai.net/g/$nhentai_id" \
						| grep 'meta itemprop="name"' \
						| sed -e 's/.*<meta itemprop="name" content="//' -e 's/".*//' \
						| sed -e 's/[[:punct:]]//g' -e 's/\s/_/g')
					nhentai_ext=$(grep 'img src' <<< "$nhentai_check" \
						| sed -e 's/.*<img src="//' -e 's/".*//' \
						| sed 's/.*\.//')
					mkdir "nhentai-$nhzip_id"
					for x in $(seq $numpages); do
						nhentai_pic=$(wget -q -O- "https://nhentai.net/g/$nhentai_id/$x/" \
							| grep 'img src' \
							| sed -e 's/.*<img src="//' -e 's/".*//')
						wget -q -O "nhentai-$nhzip_id/pic-$x.$nhentai_ext" "$nhentai_pic"
							
							loading value "$x/$numpages"
							
					done
					zip "$nhentai_title-$nhzip_id.zip" "nhentai-$nhzip_id/"* > /dev/null
					rm -r "nhentai-$nhzip_id"
					
					if [ "$(du -m "$nhentai_title-$nhzip_id.zip" | cut -f 1)" -ge 50 ]; then
						zip_list=$(zipsplit -qn 51380220 "$nhentai_title-$nhzip_id.zip" | grep creating | sed 's/creating: //')
						zip_num=$(wc -l <<< "$zip_list")
						
							loading 2
						
						for x in $(seq $zip_num); do
							zip_file=$(sed -n ${x}p <<< "$zip_list")
							document_id="@$zip_file"
							tg_method send_document upload > /dev/null
							rm "$zip_file"
						done
							loading 3 ; return
					fi
					
					document_id="@$nhentai_title-$nhzip_id.zip"
					
						loading 2
					
					tg_method send_document upload > /dev/null
					
						loading 3
					
					rm "$nhentai_title-$nhzip_id.zip"
				else
					text_id="too many pages (max $maxpages)"
					tg_method send_message > /dev/null
				fi
			else
				text_id="invalid id"
				tg_method send_message > /dev/null
			fi
		else
			markdown=("<code>" "</code>")
			text_id="Access denied"
			tg_method send_message > /dev/null
		fi
	;;
	"!explorer "*)
		if [ $(is_admin) ] && [ "$type" = "private" ]; then
			get_reply_id self
			selected_dir=$(sed 's|/$||' <<< "$fn_arg")
			files_selected_dir=$(find "$selected_dir/" -maxdepth 1 -type f | sed "s:^./\|$selected_dir/::")
			if [ "$files_selected_dir" != "" ]; then
				text_id=$(printf '%s\n' "selected directory: $selected_dir" "select a file to download" "subdirs:" ; find "$selected_dir/" -maxdepth 1 -type d | sed "s:^./\|$selected_dir/::" | sed -e 1d | sed -e 's/^/-> /' -e 's|$|/|')
				for j in $(seq 0 $(( $(wc -l <<< "$files_selected_dir") -1 )) ); do
					button_text[$j]=$(sed -n $((j+1))p <<< "$files_selected_dir")
					callback_data[$j]=${button_text[$j]}
				done
				markup_id=$(inline_array button)
			else
				text_id=$(printf '%s\n' "selected directory: $selected_dir" "subdirs:" ; find "$selected_dir/" -maxdepth 1 -type d | sed "s:^./\|$selected_dir/::" | sed -e 1d | sed -e 's/^/-> /' -e 's|$|/|')
			fi
			tg_method send_message > /dev/null
		else
			markdown=("<code>" "</code>")
			text_id="Access denied"
		fi
		tg_method send_message > /dev/null
	;;
	"!broadcast "*|"!broadcast")
		if [ $(is_admin) ]; then
			group_broadcast_chats=$(grep -rnw db/chats/ -e 'supergroup' | cut -d ':' -f 1 | sed 's|db/chats/||')
			private_broadcast_chats=$(grep -r users db/bot_chats/ | sed 's/.*: //' | tr ' ' '\n' | sed '/^$/d')
			listchats=$(printf '%s\n' "$group_broadcast_chats" "$private_broadcast_chats" | grep -vw -- "$chat_id")
			numchats=$(wc -l <<< "$listchats")
			text_id=$fn_arg
			br_delay=1
			if [ "$text_id" != "" ]; then
				for x in $(seq "$numchats"); do
					chat_id=$(sed -n ${x}p <<< "$listchats")
					tg_method send_message
					sleep $br_delay
				done
			elif [ "$reply_to_message" != "" ]; then
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
			text_id="Access denied"
			send_message
		fi
	;;
	"!nomedia")
		if [ "$type" != "private" ] && [ $(is_admin) ]; then
		get_reply_id self
		current_send_media=$(curl -s "${TELEAPI}/getChat" --form-string "chat_id=$chat_id" | jshon -Q -e result -e permissions -e can_send_media_messages -u)
			if [ "$current_send_media" = "true" ]; then
				can_send_messages="true"
				can_send_media_messages="false"
				can_send_other_messages="false"
				can_send_polls="false"
				can_add_web_page_previews="false"
				
				set_chat_permissions=$(tg_method set_chat_permissions | jshon -Q -e ok -u)
				
				if [ "$set_chat_permissions" = "true" ]; then
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
				
				set_chat_permissions=$(tg_method set_chat_permissions | jshon -Q -e ok -u)
				
				if [ "$set_chat_permissions" = "true" ]; then
					text_id="no-media mode deactivated"
				else
					text_id="error: bot is not admin"
				fi
			fi
			tg_method send_message > /dev/null
		else
			markdown=("<code>" "</code>")
			text_id="Access denied"
			tg_method send_message > /dev/null
		fi
	;;
	"!silence")
		if [ "$type" != "private" ] && [ $(is_admin) ]; then
		get_reply_id self
		current_send_messages=$(curl -s "${TELEAPI}/getChat" --form-string "chat_id=$chat_id" | jshon -Q -e result -e permissions -e can_send_messages -u)
			if [ "$current_send_messages" = "true" ]; then
				can_send_messages="false"
				can_send_media_messages="false"
				can_send_other_messages="false"
				can_send_polls="false"
				can_add_web_page_previews="false"
				
				set_chat_permissions=$(tg_method set_chat_permissions | jshon -Q -e ok -u)
				
				if [ "$set_chat_permissions" = "true" ]; then
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
				
				set_chat_permissions=$(tg_method set_chat_permissions | jshon -Q -e ok -u)
				
				if [ "$set_chat_permissions" = "true" ]; then
					text_id="read-only mode deactivated"
				else
					text_id="error: bot is not admin"
				fi
			fi
			tg_method send_message > /dev/null
		else
			markdown=("<code>" "</code>")
			text_id="Access denied"
			tg_method send_message > /dev/null
		fi
	;;
	"!del"|"!delete")
		if [ $(is_admin) ]; then
			to_delete_id=$reply_to_id
			tg_method delete_message > /dev/null
		fi
	;;
	"!exit")
		get_reply_id self
		if [ $(is_admin) ]; then
			text_id="goodbye"
			tg_method send_message > /dev/null
			tg_method leave_chat > /dev/null
		else
			markdown=("<code>" "</code>")
			text_id="Access denied"
			tg_method send_message > /dev/null
		fi
	;;
	
	## no prefix
	
	"respect+"|"+"|"-"|"+"*|"-"*)
		if [ "$username_id" != "$reply_to_user_id" ]; then
			# check existing lock+
			[ ! -d .lock+/respect/ ] && mkdir -p .lock+/respect/
			lockfile=.lock+/respect/"$username_id"-lock
			if [ -e $lockfile ]; then
				# if it's younger than one day return
				lock_age=$(bc <<< "$(date +%s) - $(stat -c "%W" $lockfile)")
				lock_time=$((60 + (RANDOM % 60)))
				if [ $lock_age -lt $locktime ]; then
					return
				else
					rm $lockfile
				fi
			fi
			if [ "$(grep respect <<< "$normal_message")" = "" ]; then
				rep_sign=$(sed 's/[^-+].*//' <<< "$normal_message")
				rep_n=$(sed 's/[+-]//' <<< "$normal_message")
				[ "$rep_n" = "1" ] && rep_n=""
			else
				rep_sign=$(sed 's/respect//' <<< "$normal_message")
			fi
			prevrep=$(sed -n 5p db/users/"$reply_to_user_id" | sed 's/rep: //')
			if [ "$prevrep" = "" ]; then
				printf '%s\n' "rep: 0" >> db/users/"$reply_to_user_id"
				prevrep=$(sed -n 5p db/users/"$reply_to_user_id" | sed 's/rep: //')
			fi
			reply_id=$reply_to_id
			if [ "$rep_n" = "" ]; then
				sed -i "s/rep: .*/rep: $(bc <<< "$prevrep $rep_sign 1")/" db/users/"$reply_to_user_id"
			elif [ $(is_admin) ]; then
				[ "$rep_n" -eq "$rep_n" ] || return
				sed -i "s/rep: .*/rep: $(bc <<< "$prevrep $rep_sign $rep_n")/" db/users/"$reply_to_user_id"
			else
				return
			fi
			newrep=$(sed -n 5p db/users/"$reply_to_user_id" | sed 's/rep: //')
			voice_id="https://archneek.zapto.org/webaudio/respect.ogg"
			if [ "$(grep respect <<< "$normal_message")" = "" ]; then
				case "$rep_sign" in 
					"+")
						text_id="respect + to $reply_to_user_fname ($newrep)"
						tg_method send_message > /dev/null
					;;
					"-")
						text_id="respect - to $reply_to_user_fname ($newrep)"
						tg_method send_message > /dev/null
				esac
			else
				caption="respect + to $reply_to_user_fname ($newrep)"
				tg_method send_voice > /dev/null
			fi
			# create lock+
			[ ! -e $lockfile ] && touch $lockfile
		fi
		return
	;;
	[oO][kK]|[oO][kK]?)
		text_id="ok"
		get_reply_id self
		tg_method send_message > /dev/null
	;;
	*)
		if [ "$(grep -r -- "$bot_chat_user_id" "$bot_chat_dir")" != "" ]; then
			bc_users=$(grep -r -- "$bot_chat_user_id" "$bot_chat_dir" | sed 's/.*:\s//' | tr ' ' '\n' | grep -v -- "$bot_chat_user_id")
			if [ "$bc_users" != "" ]; then
				bc_users_num=$(wc -l <<< "$bc_users")
			else
				return
			fi
			if [ "$file_type" = "text" ]; then
				if [ "$reply_to_text" != "" ]; then
					quote_reply=$(sed -n 1p <<< "$reply_to_text" | grep '^|')
					if [ "$(wc -c <<< "$reply_to_text")" -gt 30 ]; then
						if [ "$quote_reply" = "" ]; then
							quote="$(head -c 30 <<< "$reply_to_text" | sed 's/^/| /g')..."
						else
							reply_to_text=$(sed '1,2d' <<< "$reply_to_text")
							quote="$(head -c 30 <<< "$reply_to_text" | sed 's/^/| /g')..."
						fi
					else
						if [ "$quote_reply" = "" ]; then
							quote="$(head -c 30 <<< "$reply_to_text" | sed 's/^/| /g')"
						else
							reply_to_text=$(sed '1,2d' <<< "$reply_to_text")
							quote="$(head -c 30 <<< "$reply_to_text" | sed 's/^/| /g')"
						fi
					fi
					text_id=$(printf '%s\n' "$quote" "" "$normal_message")
				elif [ "$reply_to_message" != "" ] && [ "$reply_to_text" = "" ]; then
					get_file_type reply
					text_id=$(printf '%s\n' "| [$file_type]" "" "$normal_message")
				fi
				for c in $(seq "$bc_users_num"); do
					chat_id=$(sed -n ${c}p <<< "$bc_users")
					send_message_id[$c]=$(tg_method send_message > /dev/null)
				done
			else
				from_chat_id=$chat_id
				copy_id=$message_id
				for c in $(seq "$bc_users_num"); do
					chat_id=$(sed -n ${c}p <<< "$bc_users")
					send_message_id[$c]=$(tg_method copy_message > /dev/null)
				done
			fi
			for c in $(seq "$bc_users_num"); do
				if [ "$(jshon -Q -e description -u <<< "${send_message_id[$c]}")" = "Forbidden: bot was blocked by the user" ]; then
					sed -i "s/$chat_id //" "$(grep -r -- "$bot_chat_user_id" $bot_chat_dir | cut -d : -f 1)"
				fi
			done
		fi
	;;
esac
