#!/bin/bash
TOKEN=$(cat ./token)
TELEAPI="https://api.telegram.org/bot${TOKEN}"
exec 1>>neekshellbot.log 2>&1
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
function inline_booru() {
    for rig in $(seq $picnumber); do
        pic=$(echo $piclist | tr " " "\n" | sed -n "${rig}p")
        thumb=$(echo $thumblist | tr " " "\n" | sed -n "${rig}p")
        file=$(echo $filelist | tr " " "\n" | sed -n "${rig}p")
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
    for rig in $(seq $gifnumber); do
        gif=$(echo $giflist | tr " " "\n" | sed -n "${rig}p")
        file=$(echo $filelist | tr " " "\n" | sed -n "${rig}p")
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
function inline_google() {
    for x in $(seq $((resnumber-1))); do
        title=$(echo $googler_results | jq -r ".[$x].title")
        url=$(echo $googler_results | jq -r ".[$x].url")
        description=$(echo $googler_results | jq -r ".[$x].abstract")
        obj[$x]="{
        \"type\":\"article\",
        \"id\":\"$RANDOM\",
        \"title\":\"${title}\",
        \"input_message_content\":{\"message_text\":\"${title}\\n${url}\"},
        \"description\":\"${description}\"
        },"
    done
    cat <<EOF
    [ $(echo ${obj[@]} | sed -E 's/(.*)},/\1}/') ]
EOF
}
function normal_reply() {
	curl -s "${TELEAPI}/sendMessage" \
		--data-urlencode "chat_id=$chat_id" \
		--data-urlencode "parse_mode=html" \
		--data-urlencode "text=$return_feedback" > /dev/null
}
function forward_reply() {
	curl -s "${TELEAPI}/forwardMessage" \
	--data-urlencode "chat_id=$forward_id" \
	--data-urlencode "from_chat_id=$chat_id" \
	--data-urlencode "message_id=$message_id" > /dev/null
}
function inline_reply() {
	curl -s "${TELEAPI}/answerInlineQuery" \
		--data-urlencode "inline_query_id=$inline_id" \
		--data-urlencode "results=$return_query" \
		--data-urlencode "next_offset=$offset" \
		--data-urlencode "cache_time=100" \
		--data-urlencode "is_personal=true" > /dev/null
}
function get_normal_reply() {
	if [ "${pf}" = "" ]; then
		case $first_normal in	
			"+")
				curl -s "${TELEAPI}/sendVoice" --data-urlencode "chat_id=$chat_id" --data-urlencode "reply_to_message_id=$message_id" --data-urlencode "voice=https://archneek.zapto.org/webaudio/respect.ogg" > /dev/null
			;;
			*)
			if [ "$type" = "private" ]; then
				number=$(( ( RANDOM % 500 )  + 1 ))
				if		[ $number = 69 ]; then
					return_feedback="Nice."
				elif	[ $number = 1 ]; then
					return_feedback="We are number one"
				elif	[ $number -gt 250 ]; then
					return_feedback="Ok"
				elif	[ $number -lt 250 ]; then
					return_feedback="Alright"
				fi
			else
				true
			fi
			return
			;;
		esac
	else
		case $first_normal in
			"${pf}start")
				return_feedback=$(echo -e "source: https://github.com/neektwothousand/neekshell-telegrambot")
				return
			;;
			"${pf}help")
				return_feedback=$(sed -n '/normal/,/endnormal/ p' commands | sed -e '1d' -e '$d' ; echo -e "\nfor administrative commands use /admin, for inline use /inline")
				return
			;;
			"${pf}admin")
				return_feedback=$(sed -n '/admin/,/endadmin/ p' commands | sed -e '1d' -e '$d')
				return
			;;
			"${pf}inline")
				return_feedback=$(sed -n '/inline/,/endinline/ p' commands | sed -e '1d' -e '$d')
				return
			;;
			"${pf}d$normaldice")
				chars=$(( $(wc -m <<< $normaldice) - 1 ))
				return_feedback="<code>$(echo $(( ($(cat /dev/urandom | tr -dc '[:digit:]' | head -c $chars) % $normaldice) + 1 )) )</code>"
				return
			;;
			"${pf}d$normaldice*$mul")
				for x in $(seq $mul); do
					chars=$(( $(wc -m <<< $normaldice) - 1 ))
					result[$x]=$(echo $(( ($(cat /dev/urandom | tr -dc '[:digit:]' | head -c $chars) % $normaldice) + 1 )) )
				done
				return_feedback="<code>${result[@]}</code>"
				return
			;;
			"${pf}hf")
				randweb=$(( ( RANDOM % 3 ) ))
				case $randweb in
				0)
					hflist=$(curl -s "https://www.hentai-foundry.com/pictures/random/?enterAgree=1" -c hfcookie/c | grep -io '<div class="thumbTitle"><a href=['"'"'"][^"'"'"']*['"'"'"]' | sed -e 's/^<div class="thumbTitle"><a href=["'"'"']//i' -e 's/["'"'"']$//i')
					counth=$(echo $hflist | grep -c "\n")
					randh=$(sed -n "$(( ( RANDOM % $counth ) + 1 ))p" <<< $hflist)
					getrandh=$(curl --cookie hfcookie/c -s https://www.hentai-foundry.com$randh | sed -n 's/.*src="\([^"]*\)".*/\1/p' | grep "pictures.hentai" | sed "s/^/https:/")
					curl -s "${TELEAPI}/sendPhoto" --data-urlencode "chat_id=$chat_id" --data-urlencode "reply_to_message_id=$message_id" --data-urlencode "caption=https://www.hentai-foundry.com$randh" --data-urlencode "photo=$getrandh" > /dev/null
					exit 1
				;;
				1)
					randh=$(wget -q -O- 'https://rule34.xxx/index.php?page=post&s=random')
					getrandh=$(grep 'content="https://img.rule34.xxx' <<< $randh | sed -En 's/.*content="(.*)"\s.*/\1/p')
					postid=$(grep 'action="index.php?' <<< $randh | sed -En 's/.*(id=.*)&.*/\1/p')
					curl -s "${TELEAPI}/sendPhoto" --data-urlencode "chat_id=$chat_id" --data-urlencode "reply_to_message_id=$message_id" --data-urlencode "caption=https://rule34.xxx/index.php?page=post&s=view&$postid" --data-urlencode "photo=$getrandh" > /dev/null
					exit 1
				;;
				2)
					randh=$(wget -q -O- 'https://safebooru.org/index.php?page=post&s=random')
					getrandh=$(grep 'content="https://safebooru.org' <<< $randh | sed -En 's/.*content="(.*)"\s.*/\1/p')
					postid=$(grep 'action="index.php?' <<< $randh | sed -En 's/.*(id=.*)&.*/\1/p')
					curl -s "${TELEAPI}/sendPhoto" --data-urlencode "chat_id=$chat_id" --data-urlencode "reply_to_message_id=$message_id" --data-urlencode "caption=https://safebooru.org/index.php?page=post&s=view&$postid" --data-urlencode "photo=$getrandh" > /dev/null
					exit 1
				;;
				esac
				return
			;;
			"${pf}w$trad "*)
				search=$(sed -e "s/[/!]w$trad //" -e 's/\s/%20/g' <<< $first_normal)
				wordreference=$(curl -A 'neekshellbot/1.0' -s "https://www.wordreference.com/$trad/$search" | sed -En "s/.*\s>(.*\s)<em.*/\1/p" | sed -e "s/<a.*//g" -e "s/<span.*'\(.*\)'.*/\1/g" | head | awk '!x[$0]++')
				[ "$wordreference" != "" ] && return_feedback=$(echo -e "translations:\n$wordreference") || return_feedback="$(echo "$search" | sed 's/%20/ /g') not found"
				return
			;;
			"${pf}setadmin "*)
				admin=$(grep -v "#" neekshelladmins | grep -w $username_id)
				if [ "$admin" != ""  ]; then
					username=$(sed -e 's/[/!]setadmin @//' <<< $first_normal)
					setadmin_id=$(sed -n 2p $(find neekshell_db/users/ -iname "$username") | sed "s/id: //")
					admin_check=$(grep -v "#" neekshelladmins | grep -w $setadmin_id)
					if [ -z $setadmin_id ]; then
						return_feedback=$(echo "user not found")
					elif [ "$admin_check" != "" ]; then
						return_feedback=$(echo "$username already admin")
					else
						echo -e "# $username\n$setadmin_id" >> neekshelladmins
						return_feedback=$(echo "admin $username set!")
					fi
				else
					return_feedback="<code>Access denied</code>"
				fi
				return
			;;
			"${pf}deladmin "*)
				admin=$(grep -v "#" neekshelladmins | grep -w $username_id)
				if [ "$admin" != ""  ]; then
					username=$(sed -e 's/[/!]deladmin @//' <<< $first_normal)
					deladmin_id=$(sed -n 2p $(find neekshell_db/users/ -iname "$username") | sed "s/id: //")
					admin_check=$(grep -v "#" neekshelladmins | grep -w $deladmin_id)
					if [ -z $deladmin_id ]; then
						return_feedback=$(echo "user not found")
					elif [ "x$admin_check" != "x" ]; then
						sed -i "/$username/d" neekshelladmins
						sed -i "/$deladmin_id/d" neekshelladmins
						return_feedback=$(echo "$username is no longer admin")
					else
						echo "$username is not admin"
					fi
				else
					return_feedback="<code>Access denied</code>"
				fi
				return
			;;
			"${pf}bin "*)
				admin=$(grep -v "#" neekshelladmins | grep -w $username_id)
				if [ "$admin" != "" ]; then
					command=$(sed 's/[/!]bin //' <<< "$first_normal")
					return_feedback=$(eval "$command" 2>&1)
					return_feedback="<code>$(sed 's/[<]/\&lt;/g' <<< $return_feedback)</code>"
				else
					return_feedback="<code>Access denied</code>"
				fi
				return
			;;
			"${pf}cpustat")
				cpustat=$(awk -v a="$(awk '/cpu /{print $2+$4,$2+$4+$5}' /proc/stat; sleep 1)" '/cpu /{split(a,b," "); print 100*($2+$4-b[1])/($2+$4+$5-b[2])}' /proc/stat | sed -E 's/(.*)\..*/\1%/')
				return_feedback=$cpustat
			;;
			"${pf}broadcast "*|"${pf}broadcast")
				admin=$(grep -v "#" neekshelladmins | grep -w $username_id)
				if [ "$admin" != "" ]; then
					listchats=$(grep -rnw neekshell_db/chats/ -e 'supergroup' | cut -d ':' -f 1)
					numchats=$(wc -l <<< "$listchats")
					return_feedback=$(sed "s/[!/]broadcast//" <<< $first_normal)
					if [ "$return_feedback" != "" ]; then
						for x in $(seq $numchats); do
							brid[$x]=$(sed -n 2p "$(sed -n ${x}p <<< "$listchats")" | sed 's/id: //')
							chat_id=${brid[$x]}
							normal_reply
							sleep 2
						done
					elif [ "$message_id" != "null" ]; then
						return_feedback=$(jq -r ".reply_to_message.text" <<< $message)
						if [ "$return_feedback" = "" ]; then
							for x in $(seq $numchats); do
								forward_id=$(sed -n 2p "$(sed -n ${x}p <<< "$listchats")" | sed 's/id: //')
								forward_reply
								sleep 2
							done
						else
							for x in $(seq $numchats); do
								brid[$x]=$(sed -n 2p "$(sed -n ${x}p <<< "$listchats")" | sed 's/id: //')
								chat_id=${brid[$x]}
								normal_reply
								sleep 2
							done
						fi
					else
						return_feedback="Write something after broadcast command or reply to forward"
						normal_reply
					fi
					exit
				else
					return_feedback="<code>Access denied</code>"
				fi
				return
			;;
			"${pf}fortune")
				return_feedback="$(/usr/bin/fortune fortunes paradoxum goedel linuxcookie | tr '\n' ' ' | awk '{$2=$2};1')"
				return
			;;
			"${pf}owoifer"|"${pf}cringe")
				reply=$(jq -r ".reply_to_message.text" <<< $message)
				if [ "$reply" != "null" ]; then
					[ "$first_normal" = "${pf}cringe" ] && owoarray=(" 🥵 " " 🙈 " " 🤣 " " 😘 " " 🥺 " " 💁‍♀️ " " OwO " " 😳 " " 🤠 " " 🤪 " " 😜 " " 🤬 " " 🤧 " " 🦹‍♂ ") || owoarray=(" owo " " ewe " " uwu ")
					numberspace=$(sed 's/ / \n/g' <<< $reply | grep -c " ")
					number=$(bc <<< "$numberspace / 3")
					resultspace=$(echo "$number" ; bc <<< "$number + $number" ; bc <<< "$number*3")
					tempspace=$(sed -e "s/\s/\n/g" <<< $resultspace)
					for rig in 1 2 3; do
						spacerandom[$rig]=$(sed -n "${rig}p" <<< $tempspace)
						cringerandom[$rig]=${owoarray[$(( ( RANDOM % ${#owoarray[@]} )  + 0 ))]}
					done
					emoji=$(sed -e "s/ /${cringerandom[1]}/${spacerandom[1]}" -e "s/ /${cringerandom[2]}/${spacerandom[2]}" -e "s/ /${cringerandom[3]}/${spacerandom[3]}" <<< $reply)
					return_feedback=$(sed -e 's/[lr]/w/g' -e 's/[LR]/W/g' <<< $emoji)
				else
					exit 1
				fi
				return
			;;
			"${pf}sed "*)
				regex=$(sed -e 's/[/!]sed //' <<< $first_normal)
				sed=$(jq -r ".reply_to_message.text" <<< $message | sed -En "s/$regex/p")
				return_feedback=$(echo "<b>FTFY:</b>" ; echo "$sed")
				return
			;;
			"${pf}ping")
				return_feedback=$(echo "pong" ; ping -c 1 api.telegram.org | grep time= | sed -E "s/(.*time=)(.*)( ms)/\2ms/")
				return
			;;
			"${pf}bang")
				if [ $type != "private" ]; then
				admin=$(grep -v "#" neekshelladmins | grep -w $username_id)
					if [ "$admin" != "" ]
					then
						username=$(jq -r ".reply_to_message.from.username" <<< $message)
						userid=$(jq -r ".reply_to_message.from.id" <<< $message)
						curl -s "${TELEAPI}/restrictChatMember" --data-urlencode "chat_id=$chat_id" --data-urlencode "user_id=$userid" --data-urlencode "can_send_messages=false" --data-urlencode "until_date=32477736097" > /dev/null & curl -s "${TELEAPI}/sendSticker" --data-urlencode "chat_id=$chat_id" --data-urlencode "reply_to_message_id=$message_id" --data-urlencode "caption=prova" --data-urlencode "sticker=https://archneek.zapto.org/webpics/vicious_dies2.webp" & curl -s "${TELEAPI}/sendMessage" --data-urlencode "chat_id=$chat_id" --data-urlencode "reply_to_message_id=$message_id" --data-urlencode "parse_mode=html" --data-urlencode "text=$( [ "$username" != "null" ] && echo "@$username (<a href=\"tg://user?id=$userid\">$userid</a>) terminato" || echo "<a href=\"tg://user?id=$userid\">$userid</a> terminato")" > /dev/null 
						exit 1
					else
						curl -s "${TELEAPI}/sendMessage" --data-urlencode "chat_id=$chat_id" --data-urlencode "parse_mode=html" --data-urlencode "text=<code>Access denied</code>" > /dev/null
						exit 1
					fi
				else
				exit 1
				fi
				return
			;;
			"${pf}nomedia")
				if [ $type != "private" ]; then
				admin=$(grep -v "#" neekshelladmins | grep -w $username_id)
					if [ "$admin" != "" ]
					then
						if [ "$(curl -s "${TELEAPI}/getChat" --data-urlencode "chat_id=$chat_id" | jq -r ".result.permissions.can_send_media_messages")" = "true" ]; then
						perms=$(jq -n --arg ci "$chat_id" '{chat_id: $ci, permissions: {can_send_messages: true, can_send_media_messages: false, can_send_other_messages: false, can_send_polls: false, can_add_web_page_previews: false}}')
						curl -s "${TELEAPI}/setChatPermissions" -d "$perms" -H 'Content-Type: application/json' > /dev/null & \
						curl -s "${TELEAPI}/sendMessage" --data-urlencode "chat_id=$chat_id" --data-urlencode "reply_to_message_id=$message_id" --data-urlencode "parse_mode=html" --data-urlencode "text=no-media mode activated, send again to deactivate" > /dev/null 
						exit 1
						else
						perms=$(jq -n --arg ci "$chat_id" '{chat_id: $ci, permissions: {can_send_messages: true, can_send_media_messages: true, can_send_other_messages: true, can_send_polls: true, can_add_web_page_previews: true}}')
						curl -s "${TELEAPI}/setChatPermissions" -d "$perms" -H 'Content-Type: application/json' > /dev/null & \
						curl -s "${TELEAPI}/sendMessage" --data-urlencode "chat_id=$chat_id" --data-urlencode "reply_to_message_id=$message_id" --data-urlencode "parse_mode=html" --data-urlencode "text=no-media mode deactivated" > /dev/null 
						exit 1
						fi
					else
						curl -s "${TELEAPI}/sendMessage" --data-urlencode "chat_id=$chat_id" --data-urlencode "parse_mode=html" --data-urlencode "text=<code>Access denied</code>" > /dev/null
						exit 1
					fi
				else
				exit 1
				fi
				return
			;;
			"${pf}exit")
				admin=$(grep -v "#" neekshelladmins | grep -w $username_id)
				if [ "$admin" != "" ]; then
					curl -s "$TELEAPI/leaveChat" --data-urlencode "chat_id=$chat_id" > /dev/null
					exit 1
				else
					curl -s "${TELEAPI}/sendMessage" --data-urlencode "chat_id=$chat_id" --data-urlencode "parse_mode=html" --data-urlencode "text=<code>Access denied</code>" > /dev/null
					exit 1
				fi
			;;
			"${pf}tag "*)
				username=$(sed -E 's/.* (\[.*\]) .*/\1/' <<< $first_normal | tr -d '[@]')
				usertext=$(sed -E 's/^.*\s.*\s(\(.*)/\1/' <<< $first_normal | tr -d '()')
				userid=$(sed -n 2p $(find neekshell_db/users/ -iname "$username") | sed "s/id: //")
				[ "$userid" != "" ] && [ "$usertext" != "" ] && return_feedback=$(echo -e "<a href=\"tg://user?id=$userid\">$usertext</a>")
				[ "$userid" = "" ] && return_feedback="$username not found"
				return
			;;
			"${pf}forward "*)
			if [ $type = "private" ]; then
				username=$(echo $first_normal | sed -e 's/[/!]forward @//')
				[ ! -e "$(find neekshell_db/users/ -iname "$username")" ] && curl -s "${TELEAPI}/sendMessage" --data-urlencode "chat_id=$chat_id" --data-urlencode "reply_to_message_id=$message_id" --data-urlencode "parse_mode=html" --data-urlencode "text=User not found" > /dev/null && exit 1
				forward_id=$(sed -n 2p $(find neekshell_db/users/ -iname "$username") | sed "s/id: //")
				curl -s "${TELEAPI}/forwardMessage" --data-urlencode "chat_id=$forward_id" --data-urlencode "from_chat_id=$chat_id" --data-urlencode "message_id=$message_id" > /dev/null & curl -s "${TELEAPI}/sendMessage" --data-urlencode "chat_id=$chat_id" --data-urlencode "reply_to_message_id=$message_id" --data-urlencode "parse_mode=html" --data-urlencode "text=Sent" > /dev/null
			else
				exit 1
			fi
			return
			;;
		esac
	fi
}
function get_inline_reply(){
	inlinedice=$(echo $results | tr -d '[:alpha:]')
	[ "$(grep -w "gb\|gbgif" <<< $results)" != "" ] && booru="gelbooru.com" && ilb="g"
	[ "$(grep -w "xb\|xbgif" <<< $results)" != "" ] && booru="xbooru.com" && ilb="x"
	[ "$(grep -w "realb\|realbgif" <<< $results)" != "" ] && booru="realbooru.com" && ilb="real"
	[ "$(grep -w "r34b\|r34bgif" <<< $results)" != "" ] && booru="rule34.xxx" && ilb="r34"
    case $results in
        "help")
			title="Ok"
			message_text="Ok"
			description=",\"description\":\"Alright\""
            return_query=$(inline_article)
	    return
        ;;
		"d$inlinedice")
		if [ "$inlinedice" != "" ]
			then
			title="Result of d$inlinedice"
			number=$(( ( RANDOM % $inlinedice )  + 1 ))
			message_text=$(echo -e "Result of d$inlinedice\n: $number")
			return_query=$(inline_article)
		fi
		return
		;;
        *" bin")
			admin=$(grep -v "#" neekshelladmins | grep -w $inline_user_id)
            if [ "$admin" != "" ]; then
				command=$(sed 's/ bin//' <<< $results)
				ecommand="echo \$($command)"
                title="$(echo "$~> "$command"" ; eval $(echo "timeout 5s $(echo $command)") 2>&1 )"
                message_text="<code>$title</code>"
                return_query=$(inline_article)
            fi
	    return
        ;;
		"tag "*)
			username=$(sed -Ee 's/(.* )(\[.*\]) ((.*))/\2/' -e 's/[[:punct:]]//g' <<< $results)
			title=$(sed -Ee 's/(.* )(\[.*\]) ((.*))/\3/' -Ee 's/[[:punct:]](.*)[[:punct:]]/\1/' <<< $results)
			userid=$(sed -n 2p $(find neekshell_db/users/ -iname "$username") | sed "s/id: //")
			message_text="<a href=\\\"tg://user?id=$userid\\\">$title</a>"
			description=",\"description\":\"$username\""
			return_query=$(inline_article)
			return
		;;
        'search '*)
			offset=$(($(jq -r ".offset" <<< $inline)+1))
			search=$(sed 's/search //' <<< $results)
			googler_results=$(PYTHONIOENCODING="utf-8" /usr/local/bin/googler --unfilter --json -n 5 -s "$offset" "$search")
			resnumber=$(jq -r ". | length" <<< $googler_results)
			if [ "$offset" != 1 ]; then
				nextpage=$(($offset+$resnumber))
				googler_results=$(PYTHONIOENCODING="utf-8" /usr/local/bin/googler --unfilter --json -n 5 -s "$nextpage" "$search")
				return_query=$(inline_google)
			else
				return_query=$(inline_google)
			fi
			return
        ;;
        "${ilb}b "*)
			offset=$(($(jq -r ".offset" <<< $inline)+1))
			tags=$(sed "s/${ilb}b //" <<< $results)
			getbooru=$(curl -A 'Mozilla/5.0' -s "https://$booru/index.php?page=dapi&s=post&pid=$offset&tags=$tags&q=index&limit=5")
			thumblist=$(sed -n 's/.*preview_url="\([^"]*\)".*/\1/p' <<< $getbooru | grep -E 'jpg|jpeg|png')
			piclist=$(sed -n 's/.*sample_url="\([^"]*\)".*/\1/p' <<< $getbooru | grep -E 'jpg|jpeg|png')
			filelist=$(sed -n 's/.*file_url="\([^"]*\)".*/\1/p' <<< $getbooru | grep -E 'jpg|jpeg|png')
			picnumber=$(sed -n 's/.*sample_url="\([^"]*\)".*/\1/p' <<< $getbooru | grep -E -c 'jpg|jpeg|png')
			return_query=$(inline_booru)
			return
		;;
        "${ilb}bgif "*)
            offset=$(($(jq -r ".offset" <<< $inline)+1))
            tags=$(sed "s/${ilb}bgif //" <<< $results)
            if [ "$ilb" != "g" ]; then
				getbooru=$(curl -A 'Mozilla/5.0' -s "https://$booru/index.php?page=dapi&s=post&pid=$offset&tags=gif+$tags&q=index&limit=20")
			else
				getbooru=$(curl -A 'Mozilla/5.0' -s "https://$booru/index.php?page=dapi&s=post&pid=$offset&tags=animated+$tags&q=index&limit=20")
			fi
            giflist=$(sed -n 's/.*sample_url="\([^"]*\)".*/\1/p' <<< $getbooru | grep -E 'gif')
            filelist=$(sed -n 's/.*file_url="\([^"]*\)".*/\1/p' <<< $getbooru | grep -E 'gif')
            gifnumber=$(sed -n 's/.*sample_url="\([^"]*\)".*/\1/p' <<< $getbooru | grep -E -c 'gif')
            return_query=$(inline_boorugif)
	    return
        ;;
        *)
			title="Ok"
			message_text="Ok"
			description=",\"description\":\"Alright\""
            return_query=$(inline_article)
	    return
        ;;
    esac
}
function process_reply() {
	message=$(jq -r ".message" <<< $input)
	
    # user database
	username_tag=$(jq -r ".from.username" <<< $message) username_id=$(jq -r ".from.id" <<< $message)
	if [ "$username_tag" != "null" ]; then
		[ ! -d neekshell_db/users/ ] && mkdir -p neekshell_db/users/
		file_user=neekshell_db/users/$username_tag
		[ ! -e "$file_user" ] && echo -e "tag: $username_tag\nid: $username_id" > $file_user
	fi
	# chat database
	chat_title=$(jq -r ".chat.title" <<< $message) chat_id=$(jq -r ".chat.id" <<< $message) type=$(jq -r ".chat.type" <<< $message)
	if [ "$chat_title" != "null" ]; then
		[ ! -d neekshell_db/chats/ ] && mkdir -p neekshell_db/chats/
		file_chat="neekshell_db/chats/$chat_title"
		[ ! -e "$file_chat" ] && echo "title: $chat_title" > "$file_chat" && echo -e "id: $chat_id\ntype: $type" >> "$file_chat"
	fi
	
	[ ! -e ./botinfo ] && touch ./botinfo && wget -q -O ./botinfo "${TELEAPI}/getMe"
	text=$(jq -r ".text" <<< $message)
	pf=${text/[^\/\!]*/}

	message_id=$(jq -r ".reply_to_message.message_id" <<< $message)
	[ "$message_id" = "null" ] && message_id=$(jq -r ".message_id" <<< $message)

	inline=$(jq -r ".inline_query" <<< $input)
	inline_user=$(jq -r ".from.username" <<< $inline) inline_user_id=$(jq -r ".from.id" <<< $inline) inline_id=$(jq -r ".id" <<< $inline) results=$(jq -r ".query" <<< $inline)

	first_normal=${text/@$(jq -r ".result.username" botinfo)/}
	[ "${first_normal/*[^0-9]/}" != "" ] && normaldice=$(echo $first_normal | tr -d '/![:alpha:]' | sed 's/\*.*//g') mul=$(echo $first_normal | tr -d '/![:alpha:]' | sed 's/.*\*//g')
	trad=$(sed -e 's/[!/]w//' -e 's/\s.*//' <<< $first_normal | grep "enit\|iten")
	
	[ "$text" != "null" ] && get_normal_reply || get_inline_reply
	
	if [ "$text" != "null" ] && [ "$return_feedback" != "" ]; then
		curl -s "${TELEAPI}/sendMessage" \
			--data-urlencode "chat_id=$chat_id" \
			--data-urlencode "reply_to_message_id=$message_id" \
			--data-urlencode "parse_mode=html" \
			--data-urlencode "text=$return_feedback" > /dev/null
	elif [ "$results" != "null" ]; then
		curl -s "${TELEAPI}/answerInlineQuery" \
		--data-urlencode "inline_query_id=$inline_id" \
		--data-urlencode "results=$return_query" \
		--data-urlencode "next_offset=$offset" \
		--data-urlencode "cache_time=100" \
		--data-urlencode "is_personal=true" > /dev/null
	fi
	if	[ "$text" != "null" ] && [ "$type" = "private" ]; then
		echo "--" ; echo "normal=${text}" ; echo "from ${username_tag} at $(date "+%Y-%m-%d %H:%M")" ; echo "--"
	elif [ "$results" != "null" ] && [ -n "$results" ]; then
		echo "--" ; echo "inline=${results}" ; echo "from ${inline_user} at $(date "+%Y-%m-%d %H:%M")" ; echo "--"
	fi
}
input=$1
process_reply
