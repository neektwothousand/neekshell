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
    while [ $rig -le $picnumber ]; do
        pic=$(echo $piclist | tr " " "\n" | sed -n "${rig}p")
        thumb=$(echo $thumblist | tr " " "\n" | sed -n "${rig}p")
        file=$(echo $filelist | tr " " "\n" | sed -n "${rig}p")
        obj[$el]="{ 
        \"type\":\"photo\", 
        \"id\":\"$RANDOM\", 
        \"photo_url\":\"${pic}\", 
        \"thumb_url\":\"${thumb}\",
        \"caption\":\"tag: ${tags}\\nsource: ${file}\"
        },"
        rig=$(( $rig + 1 ))
        el=$(( $el + 1 ))
    done
    cat <<EOF
    [ $(echo ${obj[@]} | sed -E 's/(.*)},/\1}/') ]
EOF
}
function inline_boorugif() {
    while [ $rig -le $gifnumber ]; do
        gif=$(echo $giflist | tr " " "\n" | sed -n "${rig}p")
        file=$(echo $filelist | tr " " "\n" | sed -n "${rig}p")
        obj[$el]="{ 
        \"type\":\"gif\", 
        \"id\":\"$RANDOM\", 
        \"gif_url\":\"${gif}\", 
        \"thumb_url\":\"${gif}\",
        \"caption\":\"tag: ${tags}\\nsource: ${file}\"
        },"
        rig=$(( $rig + 1 ))
        el=$(( $el + 1 ))
    done
    cat <<EOF
    [ $(echo ${obj[@]} | sed -E 's/(.*)},/\1}/') ]
EOF
}
function inline_google() {
	x=0
    while [ $x -le "$(bc <<< "$resnumber - 1")" ]; do
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
        x=$(( $x + 1 ))
    done
    cat <<EOF
    [ $(echo ${obj[@]} | sed -E 's/(.*)},/\1}/') ]
EOF
}
function get_normal_reply() {
	case $first_normal in
		"${pf}start")
			return_feedback=$(echo -e "source: https://github.com/neektwothousand/neekshell-telegrambot")
			return
		;;
		"${pf}help")
			return_feedback=$(echo -e "!d[number] (dice)\n!fortune (fortune cookie)\n!owoifer (on reply)\n!hf (random hentai pic)\n!sed [regexp] (on reply)\n!forward [usertag] (in private, on reply)\n!tag [[@username] (new tag text)] (in private)\n!ping\n\nadministrative commands:\n\n!bin [system command]\n!setadmin @username\n!deladmin @username\n!nomedia (disable media messages)\n!bang (on reply to mute)\n\ninline mode:\n\nd[number] (dice)\n[system command] bin\ntag [[@username] (new tag text)]\nsearch [text to search on google]\ngbooru [gelbooru pic tag]\nrbooru [realbooru pic tag]\nxbooru [xbooru pic tag]\ngboorugif [gelbooru gif tag]\nrboorugif [realbooru gif tag]\nxboorugif [xbooru gif tag]")
			return
		;;
		"${pf}d$normaldice")
			return_feedback=$(echo $(( ( RANDOM % $normaldice )  + 1 )))
			return
		;;
		"${pf}hf")
			randweb=$(( ( RANDOM % 4 ) ))
			case $randweb in
			0)
				hflist=$(curl -s https://www.hentai-foundry.com/pictures/random/?enterAgree=1 -c hfcookie/c | grep -io '<div class="thumbTitle"><a href=['"'"'"][^"'"'"']*['"'"'"]' | sed -e 's/^<div class="thumbTitle"><a href=["'"'"']//i' -e 's/["'"'"']$//i')
				counth=$(echo $hflist | grep -c "\n")
				randh=$(sed -n "$(( ( RANDOM % $counth ) + 1 ))p" <<< $hflist)
				getrandh=$(curl --cookie hfcookie/c -s https://www.hentai-foundry.com$randh | sed -n 's/.*src="\([^"]*\)".*/\1/p' | grep "pictures.hentai" | sed "s/^/https:/")
				curl -s "${TELEAPI}/sendPhoto" --data-urlencode "chat_id=$chat_id" --data-urlencode "reply_to_message_id=$message_id" --data-urlencode "caption=https://www.hentai-foundry.com$randh" --data-urlencode "photo=$getrandh" > /dev/null
				exit 1
			;;
			1)
				randh=$(curl -A 'neekshellbot/1.0 (by neek)' -s https://e621.net/posts/random.json)
				getrandh=$(jq -r ".post.file.url" <<< $randh)
				postid=$(jq -r ".post.id" <<< $randh)
				curl -s "${TELEAPI}/sendPhoto" --data-urlencode "chat_id=$chat_id" --data-urlencode "reply_to_message_id=$message_id" --data-urlencode "caption=https://e621.net/posts/$postid" --data-urlencode "photo=$getrandh" > /dev/null
				exit 1
			;;
			2)
				randh=$(wget -q -O- 'https://rule34.xxx/index.php?page=post&s=random')
				getrandh=$(grep 'content="https://img.rule34.xxx' <<< $randh | sed -En 's/.*content="(.*)"\s.*/\1/p')
				postid=$(grep 'action="index.php?' <<< $randh | sed -En 's/.*(id=.*)&.*/\1/p')
				curl -s "${TELEAPI}/sendPhoto" --data-urlencode "chat_id=$chat_id" --data-urlencode "reply_to_message_id=$message_id" --data-urlencode "caption=https://rule34.xxx/index.php?page=post&s=view&$postid" --data-urlencode "photo=$getrandh" > /dev/null
				exit 1
			;;
			3)
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
			search=$(sed -e "s/[/!]w$trad //" <<< $first_normal)
			wordreference=$(curl -A 'neekshellbot/1.0' -s "https://www.wordreference.com/$trad/$search" | sed -En "s/.*\s>(.*\s)<em.*/\1/p" | sed -e "s/<a.*//g" -e "s/<span.*'\(.*\)'.*/\1/g" | head | awk '!x[$0]++')
			[ "$wordreference" != "" ] && return_feedback=$(echo -e "translations:\n$wordreference") || return_feedback="$search not found"
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
			if [ "$admin" != "" ]
				then
				command=$(sed 's/[/!]bin //' <<< $first_normal)
				ecommand="echo \$($command)"
				return_feedback="$(echo "$~> $command" ; eval $(echo "timeout 2s $(echo $command)") 2>&1 )"
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
				x=0
				rig=1
				while [ $x -lt "3" ]; do
					spacerandom[$x]=$(sed -n "${rig}p" <<< $tempspace)
					cringerandom[$x]=${owoarray[$(( ( RANDOM % ${#owoarray[@]} )  + 0 ))]}
					rig=$(( $rig + 1 ))
					x=$(( $x + 1 ))
				done
				emoji=$(sed -e "s/ /${cringerandom[0]}/${spacerandom[0]}" -e "s/ /${cringerandom[1]}/${spacerandom[1]}" -e "s/ /${cringerandom[2]}/${spacerandom[2]}" <<< $reply)
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
					curl -s "${TELEAPI}/restrictChatMember" --data-urlencode "chat_id=$chat_id" --data-urlencode "user_id=$userid" --data-urlencode "can_send_messages=false" --data-urlencode "until_date=32477736097" > /dev/null & curl -s "${TELEAPI}/sendMessage" --data-urlencode "chat_id=$chat_id" --data-urlencode "reply_to_message_id=$message_id" --data-urlencode "parse_mode=html" --data-urlencode "text=$( [ "$username" != "null" ] && echo -e "<b>boom</b>\nutente @$username (<a href=\"tg://user?id=$userid\">$userid</a>) terminato" || echo -e "<b>boom</b>\nutente <a href=\"tg://user?id=$userid\">$userid</a> terminato")" > /dev/null 
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
		"${pf}tag "*)
		if [ $type = "private" ]; then
			username=$(sed -Ee 's/(.* )(\[.*\]) ((.*))/\2/' -e 's/[[:punct:]]//g' <<< $first_normal)
			usertext=$(sed -Ee 's/(.* )(\[.*\]) ((.*))/\3/' -Ee 's/[[:punct:]](.*)[[:punct:]]/\1/' <<< $first_normal)
			userid=$(sed -n 2p $(find neekshell_db/users/ -iname "$username") | sed "s/id: //")
			return_feedback=$(echo -e "<a href=\"tg://user?id=$userid\">$usertext</a>")
		else
			exit 1
		fi
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
}
function get_inline_reply() {
	inlinedice=$(echo $results | tr -d '[:alpha:]')
	[ "$(grep -w "gbooru\|gboorugif" <<< $results)" != "" ] && booru="gelbooru.com" && ilb="g"
	[ "$(grep -w "xbooru\|xboorugif" <<< $results)" != "" ] && booru="xbooru.com" && ilb="x"
	[ "$(grep -w "rbooru\|rboorugif" <<< $results)" != "" ] && booru="realbooru.com" && ilb="r"
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
        "${ilb}booru "*)
            el=0
            rig=1
            offset=$(($(jq -r ".offset" <<< $inline)+1))
            tags=$(sed "s/${ilb}booru //" <<< $results)
			getbooru=$(curl -A 'Mozilla/5.0' -s "https://$booru/index.php?page=dapi&s=post&pid=$offset&tags=$tags&q=index&limit=20")
            thumblist=$(sed -n 's/.*preview_url="\([^"]*\)".*/\1/p' <<< $getbooru | grep -E 'jpg|jpeg|png')
            piclist=$(sed -n 's/.*sample_url="\([^"]*\)".*/\1/p' <<< $getbooru | grep -E 'jpg|jpeg|png')
            filelist=$(sed -n 's/.*file_url="\([^"]*\)".*/\1/p' <<< $getbooru | grep -E 'jpg|jpeg|png')
            picnumber=$(sed -n 's/.*sample_url="\([^"]*\)".*/\1/p' <<< $getbooru | grep -E -c 'jpg|jpeg|png')
            return_query=$(inline_booru)
	    return
		;;
        "${ilb}boorugif "*)
            el=0
            rig=1
            offset=$(($(jq -r ".offset" <<< $inline)+1))
            tags=$(sed "s/${ilb}boorugif //" <<< $results)
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
	pf=$(sed -En 's/.*(^[/!]).*/\1/p' <<< $text)
	[ "$pf" = "" ] && [ "$type" != "$(grep -w 'private\|null' <<< $type)" ] && exit 1

	message_id=$(jq -r ".reply_to_message.message_id" <<< $message)
	[ "$message_id" = "null" ] && message_id=$(jq -r ".message_id" <<< $message)

	inline=$(jq -r ".inline_query" <<< $input)
	inline_user=$(jq -r ".from.username" <<< $inline) inline_user_id=$(jq -r ".from.id" <<< $inline) inline_id=$(jq -r ".id" <<< $inline) results=$(jq -r ".query" <<< $inline)

	first_normal=$(echo $text | sed "s/@$(jq -r ".result.username" botinfo)//")
	normaldice=$(echo $first_normal | tr -d '/![:alpha:]')
	trad=$(sed -En 's/([/!]w)(.*)\s.*/\2/p' <<< $first_normal | grep "enit\|iten")
	
	[ "$text" != "null" ] && get_normal_reply || get_inline_reply
	
	if [ "$text" != "null" ] && [ "$return_feedback" != "" ]; then
		curl -s "${TELEAPI}/sendMessage" --data-urlencode "chat_id=$chat_id" --data-urlencode "reply_to_message_id=$message_id" --data-urlencode "parse_mode=html" --data-urlencode "text=$return_feedback" > /dev/null
	elif [ "$results" != "null" ]; then
		curl -s "${TELEAPI}/answerInlineQuery" --data-urlencode "inline_query_id=$inline_id" --data-urlencode "results=$return_query" --data-urlencode "next_offset=$offset" --data-urlencode "cache_time=100" --data-urlencode "is_personal=true" > /dev/null
	fi
	if	[ "$text" != "null" ] && [ "$type" = "private" ]; then
		echo "--" ; echo "normal=${text}" ; echo "from ${username_tag} at $(date "+%Y-%m-%d %H:%M")" ; echo "--"
	elif [ "$results" != "null" ] && [ -n "$results" ]; then
		echo "--" ; echo "inline=${results}" ; echo "from ${inline_user} at $(date "+%Y-%m-%d %H:%M")" ; echo "--"
	fi
}
input=$1
process_reply
