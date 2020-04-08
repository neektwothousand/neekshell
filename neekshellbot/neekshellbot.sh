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
    while [ $x -le "$(echo $resnumber - 1 | bc)" ]; do
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
function get_feedback_reply() {
	if [ "$text" != "null" ]; then
	first_normal=$(echo $text | sed "s/@$(jq -r ".result.username" botinfo)//")
	normaldice=$(echo $first_normal | tr -d '/![:alpha:]')
	case $first_normal in
		'/start')
			return_feedback=$(echo -e "source: https://github.com/neektwothousand/neekshell-telegrambot")
		;;
		'!help'|'/help')
			return_feedback=$(echo -e "!d[number] (dice)\n!fortune (fortune cookie)\n!owoifer (on reply)\n!hf (random hentai-foundry pic)\n!sed [regexp] (on reply)\n!forward [usertag] (in private, on reply)\n!tag [[@username] (new tag text)] (in private)\n!ping\n\nadministrative commands:\n\n!bin [system command]\n!setadmin @username\n!deladmin @username\n!nomedia (disable media messages)\n!bang (on reply to mute)\n\ninline mode:\n\nd[number] (dice)\n[system command] bin\ntag [[@username] (new tag text)]\nsearch [text to search on google]\ngbooru [gelbooru pic tag]\nrbooru [realbooru pic tag]\nxbooru [xbooru pic tag]\ngboorugif [gelbooru gif tag]\nrboorugif [realbooru gif tag]\nxboorugif [xbooru gif tag]")
		;;
		"!d$normaldice"|"/d$normaldice")
			return_feedback=$(echo $(( ( RANDOM % $normaldice )  + 1 )))
		;;
		'!hf'|'/hf')
			randweb=$(( ( RANDOM % 2 ) ))
			if [ "$randweb" -eq 0 ]; then
				hflist=$(curl -s https://www.hentai-foundry.com/pictures/random/?enterAgree=1 -c hfcookie | grep -io '<div class="thumbTitle"><a href=['"'"'"][^"'"'"']*['"'"'"]' | sed -e 's/^<div class="thumbTitle"><a href=["'"'"']//i' -e 's/["'"'"']$//i')
				counth=$(echo $hflist | grep -c "\n")
				randh=$(echo $hflist | sed -n "$(echo $(( ( RANDOM % $counth ) + 1 )))p")
				getrandh=$(curl --cookie hfcookie -s https://www.hentai-foundry.com$randh | sed -n 's/.*src="\([^"]*\)".*/\1/p' | grep "pictures.hentai")
				curl -s "${TELEAPI}/sendPhoto" --data-urlencode "chat_id=$chat_id" --data-urlencode "reply_to_message_id=$message_id" --data-urlencode "photo=https:$getrandh" > /dev/null
				exit 1
			else
				getrandh=$(curl -A 'neekshellbot/1.0 (by neek)' -s https://e621.net/posts/random.json | jq -r ".post.file.url")
				curl -s "${TELEAPI}/sendPhoto" --data-urlencode "chat_id=$chat_id" --data-urlencode "reply_to_message_id=$message_id" --data-urlencode "photo=$getrandh" > /dev/null
				exit 1
			fi
		;;
		"!setadmin "*|"/setadmin "*)
			admin=$(grep -v "#" neekshelladmins | grep -w $username_id)
			if [ "$admin" != ""  ]; then
				username=$(sed -e 's/[/!]setadmin @//' <<< $first_normal)
				setadmin_id=$(sed 's/\s.*$//' $(find neekshell_db/users/ -iname "$username"))
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
		;;
		"!deladmin "*|"/deladmin "*)
			admin=$(grep -v "#" neekshelladmins | grep -w $username_id)
			if [ "$admin" != ""  ]; then
				username=$(sed -e 's/[/!]deladmin @//' <<< $first_normal)
				deladmin_id=$(sed 's/\s.*$//' $(find neekshell_db/users/ -iname "$username"))
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
		;;
		"!bin "*|"/bin "*)
			admin=$(grep -v "#" neekshelladmins | grep -w $username_id)
			if [ "$admin" != "" ]
				then
				command=$(sed 's/[/!]bin //' <<< $first_normal)
				ecommand="echo \$($command)"
				return_feedback="$(echo "$~> $command" ; eval $(echo "timeout 2s $(echo $command)") 2>&1 )"
				else
				return_feedback="<code>Access denied</code>"
			fi
		;;
		"!fortune"|"/fortune")
			return_feedback="$(/usr/bin/fortune fortunes paradoxum goedel linuxcookie)"
		;;
		"!owoifer"|"/owoifer"|"!cringe"|"/cringe")
			reply=$(jq -r ".message.reply_to_message.text" tempinput)
			if [ "$reply" != "null" ]; then
				[ $(sed 's/[!/]//' <<< $first_normal) = "cringe" ] && owoarray=(" 🥵 " " 🙈 " " 🤣 " " 😘 " " 🥺 " " 💁‍♀️ " " OwO " " 😳 " " 🤠 " " 🤪 " " 😜 " " 🤬 " " 🤧 " " 🦹‍♂ ") || owoarray=(" owo " " ewe " " uwu ")
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
		;;
		"!sed "*|"/sed "*)
			regex=$(sed -e 's/[/!]sed //' <<< $first_normal)
			sed=$(jq -r ".message.reply_to_message.text" tempinput | sed -E "$regex")
			return_feedback=$(echo "<b>FTFY:</b>" ; echo "$sed")
		;;
		"!ping"|"/ping")
			return_feedback=$(echo "pong" ; ping -c 1 api.telegram.org | grep time= | sed -E "s/(.*time=)(.*)( ms)/\2ms/")
		;;
		"!bang"|"/bang")
		if [ $type != "private" ]; then
			admin=$(grep -v "#" neekshelladmins | grep -w $username_id)
			if [ "$admin" != "" ]
				then
					username=$(jq -r ".message.reply_to_message.from.username" tempinput)
					userid=$(sed 's/\s.*$//' $(find neekshell_db/users/ -iname "$username"))
					curl -s "${TELEAPI}/restrictChatMember" --data-urlencode "chat_id=$chat_id" --data-urlencode "user_id=$userid" --data-urlencode "can_send_messages=false" --data-urlencode "until_date=32477736097" > /dev/null & curl -s "${TELEAPI}/sendMessage" --data-urlencode "chat_id=$chat_id" --data-urlencode "reply_to_message_id=$message_id" --data-urlencode "parse_mode=html" --data-urlencode "text=$(echo -e "<b>boom</b>\nutente @$usertag (<a href=\"tg://user?id=$userid\">$userid</a>) terminato")" > /dev/null 
					exit 1
				else
					curl -s "${TELEAPI}/sendMessage" --data-urlencode "chat_id=$chat_id" --data-urlencode "parse_mode=html" --data-urlencode "text=<code>Access denied</code>" > /dev/null
					exit 1
			fi
		else
			exit 1
		fi
		;;
		"!nomedia"|"/nomedia")
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
		;;
		"!tag "*|"/tag "*)
		if [ $type = "private" ]; then
			username=$(sed -Ee 's/(.* )(\[.*\]) ((.*))/\2/' -e 's/[[:punct:]]//g' <<< $first_normal)
			usertext=$(sed -Ee 's/(.* )(\[.*\]) ((.*))/\3/' -Ee 's/[[:punct:]](.*)[[:punct:]]/\1/' <<< $first_normal)
			userid=$(sed 's/\s.*$//' $(find neekshell_db/users/ -iname "$username"))
			return_feedback=$(echo -e "<a href=\"tg://user?id=$userid\">$usertext</a>")
		else
			exit 1
		fi
		;;
		"!forward "*|"/forward "*)
		if [ $type = "private" ]; then
			username=$(echo $first_normal | sed -e 's/[/!]forward @//')
			[ ! -e "$(find neekshell_db/users/ -iname "$username")" ] && curl -s "${TELEAPI}/sendMessage" --data-urlencode "chat_id=$chat_id" --data-urlencode "reply_to_message_id=$message_id" --data-urlencode "parse_mode=html" --data-urlencode "text=User not found" > /dev/null && exit 1
			forward_id=$(sed 's/\s.*$//' $(find neekshell_db/users/ -iname "$username"))
			curl -s "${TELEAPI}/forwardMessage" --data-urlencode "chat_id=$forward_id" --data-urlencode "from_chat_id=$chat_id" --data-urlencode "message_id=$message_id" > /dev/null & curl -s "${TELEAPI}/sendMessage" --data-urlencode "chat_id=$chat_id" --data-urlencode "reply_to_message_id=$message_id" --data-urlencode "parse_mode=html" --data-urlencode "text=Sent" > /dev/null
		else
			exit 1
		fi
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
		;;
	esac
	elif [ "$results" != "null" ]; then
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
        ;;
		"d$inlinedice")
		if [ "$inlinedice" != "" ]
			then
			title="Result of d$inlinedice"
			number=$(( ( RANDOM % $inlinedice )  + 1 ))
			message_text=$(echo -e "Result of d$inlinedice\n: $number")
			return_query=$(inline_article)
		fi
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
        ;;
		"tag "*)
			username=$(sed -Ee 's/(.* )(\[.*\]) ((.*))/\2/' -e 's/[[:punct:]]//g' <<< $results)
			title=$(sed -Ee 's/(.* )(\[.*\]) ((.*))/\3/' -Ee 's/[[:punct:]](.*)[[:punct:]]/\1/' <<< $results)
			userid=$(sed 's/\s.*$//' $(find neekshell_db/users/ -iname "$username"))
			message_text="<a href=\\\"tg://user?id=$userid\\\">$title</a>"
			description=",\"description\":\"$username\""
			return_query=$(inline_article)
		;;
        'search '*)
            offset=$(($(jq -r ".offset" <<< $inline)+1))
            search=$(sed 's/search //' <<< $results)
            resnumber=$(PYTHONIOENCODING="utf-8" /usr/local/bin/googler --unfilter --json -n 5 -s "$offset" "$search" | jq -r ". | length")
            echo "google resnumber: $resnumber"
            if [ "$offset" = 1 ]; then
				nextpage=1
            else 
				nextpage=$(($offset+$resnumber))
			fi
            googler_results=$(PYTHONIOENCODING="utf-8" /usr/local/bin/googler --unfilter --json -n 5 -s "$nextpage" "$search")
            echo "google results: $googler_results"
            return_query=$(inline_google)
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
        ;;
        *)
			title="Ok"
			message_text="Ok"
			description=",\"description\":\"Alright\""
            return_query=$(inline_article)
        ;;
    esac
    else
    exit 1
    fi
}
function process_reply() {
	message=$(jq -r ".message" tempinput)
	message_id=$(jq -r ".reply_to_message.message_id" <<< $message)
	[ "$message_id" = "null" ] && message_id=$(jq -r ".message_id" <<< $message)
	normal_user=$(jq -r ".from.username" <<< $message) username_id=$(jq -r ".from.id" <<< $message) chat_id=$(jq -r ".chat.id" <<< $message) type=$(jq -r ".chat.type" <<< $message) text=$(jq -r ".text" <<< $message | sed 's/"/\\&/g')

	inline=$(jq -r ".inline_query" tempinput)
	inline_user=$(jq -r ".from.username" <<< $inline) inline_user_id=$(jq -r ".from.id" <<< $inline) inline_id=$(jq -r ".id" <<< $inline) results=$(jq -r ".query" <<< $inline | sed 's/"/\\&/g')
	
	# database id
	if [ "$normal_user" != "null" ] && [ "$normal_user" != "" ]; then
		[ ! -d neekshell_db/users/ ] && mkdir -p neekshell_db/users/
		file_user=neekshell_db/users/${normal_user}
		[ ! -e "$file_user" ] && touch $file_user && echo "$username_id $normal_user" > $file_user
	fi
	[ ! -e ./botinfo ] && touch ./botinfo && wget -q -O ./botinfo "${TELEAPI}/getMe"
	get_feedback_reply
	if [ "$first_normal" != "null" ] && [ -n "$first_normal" ] && [ "$return_feedback" != "" ]; then
		curl -s "${TELEAPI}/sendMessage" --data-urlencode "chat_id=$chat_id" --data-urlencode "reply_to_message_id=$message_id" --data-urlencode "parse_mode=html" --data-urlencode "text=$return_feedback" > /dev/null
	elif [ "$results" != "null" ] && [ -n "$results" ]; then
		curl -s "${TELEAPI}/answerInlineQuery" --data-urlencode "inline_query_id=$inline_id" --data-urlencode "results=$return_query" --data-urlencode "next_offset=$offset" --data-urlencode "cache_time=100" --data-urlencode "is_personal=true" > /dev/null
	fi
	if	[ "$first_normal" != "null" ] && [ -n "$first_normal" ] && [ "$type" = "private" ]; then
		echo "--" ; echo "normal=${text}" ; echo "from ${normal_user} at $(date "+%Y-%m-%d %H:%M")" ; echo "--"
	elif [ "$results" != "null" ] && [ -n "$results" ]; then
		echo "--" ; echo "inline=${results}" ; echo "from ${inline_user} at $(date "+%Y-%m-%d %H:%M")" ; echo "--"
	fi
}

process_reply
