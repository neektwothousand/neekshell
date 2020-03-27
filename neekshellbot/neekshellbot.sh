#!/bin/bash
TOKEN=$(cat ./token)
TELEAPI="https://api.telegram.org/bot${TOKEN}"
start=`date +%s%2N`
exec 1>>neekshellbot.log 2>&1
function inline_help() {
    cat <<EOF
    [{
        "type":"article",
        "id":"$RANDOM",
        "title":"Ok",
        "input_message_content": {
            "message_text":"Ok"
        },
        "description":"Alright"
    }]
EOF
}
function inline_owo() {
    cat <<EOF
    [{
        "type":"article",
        "id":"$RANDOM",
        "title":"$owo",
        "input_message_content": {
            "message_text":"$owo"
        }
    }]
EOF
}
function inline_command() {
    cat <<EOF
    [{
        "type":"article",
        "id":"$RANDOM",
        "title":"$command_result",
        "input_message_content": {
            "message_text":"<code>$command_result</code>",
            "parse_mode":"html"
        }
    }]
EOF
}
function inline_denied() {
    cat <<EOF
    [{
        "type":"article",
        "id":"$RANDOM",
        "title":"Access denied",
        "input_message_content": {
            "message_text":"<code>Access denied</code>",
            "parse_mode":"html"
        }
    }]
EOF
}
function inline_dice() {
    cat <<EOF
    [{
        "type":"article",
        "id":"$RANDOM",
        "title":"Result of d$inlinedice",
        "input_message_content": {
            "message_text":"Result of d$inlinedice\\n: $number"
        }
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
function inline_tag() {
    cat <<EOF
    [{
        "type":"article",
        "id":"$RANDOM",
        "title":"$usertext",
        "input_message_content": {
            "message_text":"<a href=\"tg://user?id=$userid\">$usertext</a>",
            "parse_mode":"html"
        },
        "description":"$usertag"
    }]
EOF
}
function get_feedback_reply() {
	first_normal=$(sed "s/@$(jq ".result.username" botinfo | sed "s/\"//g")//" <<< $text)
	normaldice=$(echo $first_normal | tr -d '/![:alpha:]')
	inlinedice=$(echo $results | tr -d '[:alpha:]')
	return_query=$(inline_help)
	case $first_normal in
		'/start')
			return_feedback=$(echo -e "source: https://github.com/neektwothousand/neekshell-telegrambot")
		;;
		'!help'|'/help')
			return_feedback=$(echo -e "!d[number] (dice)\n!fortune (fortune cookie)\n!owoifer (on reply)\n!sed [regexp] (on reply)\n!forward [usertag] (in private, on reply)\n!tag [[@username] (new tag text)] (in private)\n!ping\n\nadministrative commands:\n\n!bin [system command]\n!setadmin @username\n!deladmin @username\n!bang (on reply to mute)\n\ninline mode:\n\nd[number] (dice)\n[system command] bin\ntag [[@username] (new tag text)]\nsearch [text to search on google]\ngel [gelbooru tag]\nxbgif [xbooru gif tag]")
		;;
		"!d$normaldice"|"/d$normaldice")
			return_feedback=$(echo $(( ( RANDOM % $normaldice )  + 1 )))
		;;
		"!setadmin "*|"/setadmin "*)
			admin=$(grep -v "#" neekshelladmins | grep -w $username_id)
			if [ "$admin" != ""  ]; then
				username=$(sed -e 's/[/!]setadmin @//' <<< $first_normal)
				setadmin_id=$(sed 's/\s.*$//' neekshell_db/users/$username)
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
				deladmin_id=$(sed 's/\s.*$//' neekshell_db/users/$username)
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
				command="echo \$($(jq -r ".message.text" tempinput | sed -e 's/[/!]bin//'))"
				return_feedback="$(eval $(echo "timeout 2s $(echo $command)") 2>&1 )"
				else
				return_feedback="<code>Access denied</code>"
			fi
		;;
		"!fortune"|"/fortune")
			return_feedback="$(/usr/games/fortune fortunes paradoxum goedel linuxcookie)"
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
			return_feedback=$(echo -e "<b>FTFY:</b>\n$sed")
		;;
		"!ping"|"/ping")
			end=`date +%s%2N`
			runtime=$(bc -l <<< "$end - $start")
			return_feedback=$(echo -e "<b>pong</b>\n$SECONDS.${runtime}s")
		;;
		"!bang"|"/bang")
		if [ $type != "private" ]; then
			admin=$(grep -v "#" neekshelladmins | grep -w $username_id)
			if [ "$admin" != "" ]
				then
					usertag=$(jq -r ".message.reply_to_message.from.username" tempinput)
					userid=$(sed 's/\s.*$//' neekshell_db/users/$usertag)
					ban=$(wget -q -O/dev/null --post-data "chat_id=$chat_id&user_id=$userid&can_send_messages=false&until_date=32477736097" "${TELEAPI}/restrictChatMember" & wget --post-data "chat_id=$chat_id&reply_to_message_id=$message_id&parse_mode=html&text=$(echo -e "<b>boom</b>\nutente @$usertag (<a href=\"tg://user?id=$userid\">$userid</a>) terminato")" "${TELEAPI}/sendMessage")
				exit 1
				else
					return_denied=$(wget -q -O/dev/null --post-data "chat_id=$chat_id&parse_mode=html&text=<code>Access denied</code>" "${TELEAPI}/sendMessage")
				exit 1
			fi
		else
			exit 1
		fi
		;;
		"!tag "*|"/tag "*)
		if [ $type = "private" ]; then
			usertag=$(sed -Ee 's/(.* )(\[.*\]) ((.*))/\2/' -e 's/[[:punct:]]//g' <<< $first_normal)
			usertext=$(sed -Ee 's/(.* )(\[.*\]) ((.*))/\3/' -Ee 's/[[:punct:]](.*)[[:punct:]]/\1/' <<< $first_normal)
			userid=$(sed 's/\s.*$//' neekshell_db/users/$usertag)
			return_feedback=$(echo -e "<a href=\"tg://user?id=$userid\">$usertext</a>")
		else
			exit 1
		fi
		;;
		"!forward "*|"/forward "*)
		if [ $type = "private" ]; then
			username=$(echo $first_normal | sed -e 's/[/!]forward @//')
			forward_id=$(sed 's/\s.*$//' neekshell_db/users/$username)
			forward=$(wget -q -O/dev/null --post-data "chat_id=$forward_id&from_chat_id=$chat_id&message_id=$message_id" "${TELEAPI}/forwardMessage" )
			return_feedback="Inviato"
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
    case $results in
        "help")
            return_query=$(inline_help)
        ;;
		"d$inlinedice")
		if [ -n "$inlinedice" ]
			then
			number=$(( ( RANDOM % $inlinedice )  + 1 ))
			return_query=$(inline_dice)
		fi
		;;
        *" bin")
			admin=$(grep -v "#" neekshelladmins | grep -w $username_id)
            if [ "$admin" != "" ]
                then
                command="echo \$($(jq -r ".inline_query.query" tempinput | sed -e 's/ bin//'))"
                command_result=$(eval $(echo "timeout 2s $(echo $command)") 2>&1 )
                return_query=$(inline_command)
                else
                return_query=$(inline_denied)
            fi
        ;;
		"tag "*)
			usertag=$(sed -Ee 's/(.* )(\[.*\]) ((.*))/\2/' -e 's/[[:punct:]]//g' <<< $results)
			usertext=$(sed -Ee 's/(.* )(\[.*\]) ((.*))/\3/' -Ee 's/[[:punct:]](.*)[[:punct:]]/\1/' <<< $results)
			userid=$(sed 's/\s.*$//' neekshell_db/users/$(sed 's/@//' <<< $usertag))
			return_query=$(inline_tag)
		;;
        'search '*)
            offset=$(($(jq -r ".inline_query.offset" tempinput)+1))
            search=$(sed 's/search //g' <<< $results)
            resnumber=$(googler --unfilter --json -n 5 -s $offset $search | jq -r ". | length")
            [ $offset = 1 ] && nextpage=1 || nextpage=$(($offset+$resnumber))
            googler_results=$(googler --unfilter --json -n 5 -s $nextpage $search)
			x=0
            return_query=$(inline_google)
        ;;
        'gel '*)
            el=0
            rig=1
            offset=$(($(jq -r ".inline_query.offset" tempinput)+1))
            tags=$(sed 's/gel //g' <<< $results)
			wget --user-agent 'Mozilla/5.0' -qO - "https://gelbooru.com/index.php?page=dapi&s=post&pid=$offset&tags=$tags&q=index&limit=20&api_key=20169d287696c16948e85c8ee715241ea636662e7419186d21f3355b4432c5ba&user_id=455640" > tempgel
            thumblist=$(sed -n 's/.*preview_url="\([^"]*\)".*/\1/p' tempgel | grep -E 'jpg|jpeg|png')
            piclist=$(sed -n 's/.*sample_url="\([^"]*\)".*/\1/p' tempgel | grep -E 'jpg|jpeg|png')
            filelist=$(sed -n 's/.*file_url="\([^"]*\)".*/\1/p' tempgel | grep -E 'jpg|jpeg|png')
            picnumber=$(sed -n 's/.*sample_url="\([^"]*\)".*/\1/p' tempgel | grep -E -c 'jpg|jpeg|png')
            return_query=$(inline_booru)
        ;;
        'xb '*)
            el=0
            rig=1
            offset=$(($(jq -r ".inline_query.offset" tempinput)+1))
            tags=$(sed 's/xb //g' <<< $results)
            wget --user-agent 'Mozilla/5.0' -qO - "https://xbooru.com/index.php?page=dapi&s=post&pid=$offset&tags=$tags&q=index&limit=20" > tempxb
            thumblist=$(sed -n 's/.*preview_url="\([^"]*\)".*/\1/p' tempxb | grep -E 'jpg|jpeg|png')
            piclist=$(sed -n 's/.*sample_url="\([^"]*\)".*/\1/p' tempxb | grep -E 'jpg|jpeg|png')
            filelist=$(sed -n 's/.*file_url="\([^"]*\)".*/\1/p' tempxb | grep -E 'jpg|jpeg|png')
            picnumber=$(sed -n 's/.*sample_url="\([^"]*\)".*/\1/p' tempxb | grep -E -c 'jpg|jpeg|png')
            return_query=$(inline_booru)
        ;;
        'xbgif '*)
            el=0
            rig=1
            offset=$(($(jq -r ".inline_query.offset" tempinput)+1))
            tags=$(sed 's/xbgif //g' <<< $results)
            wget --user-agent 'Mozilla/5.0' -qO - "https://xbooru.com/index.php?page=dapi&s=post&pid=$offset&tags=gif+$tags&q=index&limit=20" > tempxbgif
            giflist=$(sed -n 's/.*sample_url="\([^"]*\)".*/\1/p' tempxbgif | grep -E 'gif')
            filelist=$(sed -n 's/.*file_url="\([^"]*\)".*/\1/p' tempxbgif | grep -E 'gif')
            gifnumber=$(sed -n 's/.*sample_url="\([^"]*\)".*/\1/p' tempxbgif | grep -E -c 'gif')
            return_query=$(inline_boorugif)
        ;;
    esac
}

function process_reply() {
	sed -e ':a;N;$!ba;s/\n/ /g' -e 's/[\]/\\&/g' -i tempinput
    message_id=$(jq -r ".message.reply_to_message.message_id" tempinput)
    [ "$message_id" = "null" ] && message_id=$(jq -r ".message.message_id" tempinput)
    normal_user=$(jq -r ".message.from.username" tempinput)
    username_id=$(jq -r ".message.from.id" tempinput)
    chat_id=$(jq -r ".message.chat.id" tempinput)
    inline_user=$(jq -r ".inline_query.from.username" tempinput)
    inline_user_id=$(jq -r ".inline_query.from.id" tempinput)
    inline_id=$(jq -r ".inline_query.id" tempinput)
    type=$(jq -r ".message.chat.type" tempinput)
	text=$(jq -r ".message.text" tempinput | sed 's/"/\\&/g')
	results=$(jq -r ".inline_query.query" tempinput | sed 's/"/\\&/g')
	# database id
	if [ "$normal_user" != "null" ] && [ "$normal_user" != "" ]; then
		[ ! -d ./neekshell_db/users/ ] && mkdir -p ./neekshell_db/users/
		file_user=./neekshell_db/users/${normal_user}
		if [ ! -f $file_user ]; then
			touch $file_user
			echo "$username_id $normal_user" > $file_user
		fi
	fi
	if [ ! -f ./botinfo ]; then
		touch ./botinfo
		wget -q -O ./botinfo "${TELEAPI}/getMe"
	fi
	get_feedback_reply
	if [ "$first_normal" != "null" ] && [ -n "$first_normal" ]; then
			send=$(wget -q -O/dev/null --post-data "chat_id=$chat_id&reply_to_message_id=$message_id&parse_mode=html&text=$return_feedback" "${TELEAPI}/sendMessage")
	elif [ "$results" != "null" ] && [ -n "$results" ]; then
			send=$(wget -q -O/dev/null --post-data "inline_query_id=$inline_id&results=$return_query&next_offset=$offset&cache_time=100&is_personal=true" "${TELEAPI}/answerInlineQuery" "${TELEAPI}/answerInlineQuery")
	fi
	if	[ "$first_normal" != "null" ] && [ -n "$first_normal" ] && [ "$type" = "private" ]; then
			echo "--" ; echo "normal=${text}" ; echo "from ${normal_user} at $(date "+%Y-%m-%d %H:%M")" ; echo "--"
	elif [ "$results" != "null" ] && [ -n "$results" ]; then
			echo "--" ; echo "inline=${results}" ; echo "from ${inline_user} at $(date "+%Y-%m-%d %H:%M")" ; echo "--"
	fi
}

process_reply
