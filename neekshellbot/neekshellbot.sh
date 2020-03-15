#!/bin/bash
TOKEN="bot token here"
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
	update=$1
	first_normal=$(echo $text | sed "s/@$(cat ./botinfo | jq ".result.username" | sed "s/\"//g")//")
	normaldice=$(echo $first_normal | tr -d '/![:alpha:]')
	inlinedice=$(echo $results | tr -d '[:alpha:]')
	return_query=$(inline_help)
	case $first_normal in
		'/start')
			return_feedback=$(echo -e "source: https://github.com/neektwothousand/neekshell-telegrambot")
		;;
		'!help'|'/help')
			return_feedback=$(echo -e "!d[number] (dice)\n!fortune (fortune cookie)\n!owoifer (on reply)\n!sed [regexp] (on reply)\n!forward [usertag] (in private, on reply)\n!tag [[@username] (new tag text)] (in private)\n!ping\n\nadministrative commands:\n\n!bin [system command]\n!setadmin @username\n!deladmin @username\n!bang (on reply to mute)\n\ninline mode:\n\nd[number] (dice)\nbin [system command]\ntag [[@username] (new tag text)]\nsearch [text to search on google]\ngel [gelbooru tag]\nxbgif [xbooru gif tag]")
		;;
		"!d$normaldice"|"/d$normaldice")
			number=$(( ( RANDOM % $normaldice )  + 1 ))
			return_feedback=$(echo $number)
		;;
		"!setadmin "*|"/setadmin "*)
			admin=$(cat neekshelladmins | grep -v "#" | grep -w $username_id)
			if [ "x$admin" != "x"  ]; then
				username=$(echo $first_normal | sed -e 's/[/!]setadmin @//')
				setadmin_id=$(cat ./neekshell_db/users/$username | sed 's/\s.*$//')
				admin_check=$(cat neekshelladmins | grep -v "#" | grep -w $setadmin_id)
				if [ -z $setadmin_id ]; then
					return_feedback=$(echo "user not found")
				elif [ "x$admin_check" != "x" ]; then
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
			admin=$(cat neekshelladmins | grep -v "#" | grep -w $username_id)
			if [ "x$admin" != "x"  ]; then
				username=$(echo $first_normal | sed -e 's/[/!]deladmin @//')
				deladmin_id=$(cat ./neekshell_db/users/$username | sed 's/\s.*$//')
				admin_check=$(cat neekshelladmins | grep -v "#" | grep -w $deladmin_id)
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
			admin=$(cat neekshelladmins | grep -v "#" | grep -w $username_id)
			if [ "x$admin" != "x" ]
				then
				command="echo \$($(echo $update | jq -r ".message.text" | sed -e 's/[/!]bin//'))"
				return_feedback="<code>$(eval $(echo "timeout 2s $command" ) 2>&1 )</code>"
				else
				return_feedback="<code>Access denied</code>"
			fi
		;;
		"!fortune"|"/fortune")
			return_feedback="$(/usr/games/fortune fortunes paradoxum goedel linuxcookie)"
		;;
		"!owoifer"|"/owoifer"|"!cringe"|"/cringe")
			reply=$(echo $update | jq -r ".message.reply_to_message.text")
			if [ "$reply" != "null" ]; then
				if	[ $(echo $first_normal | sed 's/[!/]//') = "cringe" ]; then
					owoarray=(" 🥵 " " 🙈 " " 🤣 " " 😘 " " 🥺 " " 💁‍♀️ " " OwO " " 😳 " " 🤠 " " 🤪 " " 😜 " " 🤬 " " 🤧 " " 🦹‍♂ ")
				else
					owoarray=(" owo " " ewe " " uwu ")
				fi
				numberspace=$(echo $reply | sed 's/ / \n/g' | grep -c " ")
				number=$(echo "$numberspace / 3" | bc)
				resultspace=$(echo -e "$number" && echo -e "\n$number + $number" | bc && echo -e "\n$number*3" | bc)
				tempspace=$(echo $resultspace | sed -e "s/\s/\n/g")
				x=0
				rig=1
				while [ $x -le "2" ]; do
					spacerandom[$x]=$(echo -e "$tempspace" | sed -n "${rig}p")
					cringerandom[$x]=${owoarray[$(( ( RANDOM % ${#owoarray[@]} )  + 0 ))]}
					rig=$(( $rig + 1 ))
					x=$(( $x + 1 ))
				done
				emoji=$(echo $reply | sed -e "s/ /${cringerandom[0]}/${spacerandom[0]}" -e "s/ /${cringerandom[1]}/${spacerandom[1]}" -e "s/ /${cringerandom[2]}/${spacerandom[2]}")
				owo=$(echo $emoji | sed -e 's/[lr]/w/g' -e 's/[LR]/W/g')
				return_feedback=$(echo $owo)
			else
				exit 1
			fi
		;;
		"!sed "*|"/sed "*)
			regex=$(echo $first_normal | sed -e 's/[/!]sed //')
			reply=$(echo $update | jq -r ".message.reply_to_message.text")
			sed=$(echo "$reply" | sed -E "$regex")
			return_feedback=$(echo -e "<b>FTFY:</b>\n$sed")
		;;
		"!ping"|"/ping")
			end=`date +%s%2N`
			runtime=$( echo "$end - $start" | bc -l )
			return_feedback=$(echo -e "<b>pong</b>\n$SECONDS.${runtime}s")
		;;
		"!bang"|"/bang")
		if [ $type != "private" ]; then
			admin=$(cat neekshelladmins | grep "$normal_user")
			if [ -n "$admin" ]
				then
				usertag=$(echo $update | jq -r ".message.reply_to_message.from.username")
				userid=$(cat ./neekshell_db/users/$usertag | sed 's/\s.*$//')
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
			usertag=$(echo $first_normal | sed -Ee 's/(.* )(\[.*\]) ((.*))/\2/' -e 's/[[:punct:]]//g')
			usertext=$(echo $first_normal | sed -Ee 's/(.* )(\[.*\]) ((.*))/\3/' -Ee 's/[[:punct:]](.*)[[:punct:]]/\1/')
			userid=$(cat ./neekshell_db/users/$(echo $usertag) | sed 's/\s.*$//')
			return_feedback=$(echo -e "<a href=\"tg://user?id=$userid\">$usertext</a>")
		else
			exit 1
		fi
		;;
		"!forward "*|"/forward "*)
		if [ $type = "private" ]; then
			username=$(echo $first_normal | sed -e 's/[/!]forward @//')
			forward_id=$(cat ./neekshell_db/users/$username | sed 's/\s.*$//')
			forward=$(wget -q -O/dev/null --post-data "chat_id=$forward_id&from_chat_id=$chat_id&message_id=$message_id" "${TELEAPI}/forwardMessage" )
			return_feedback="Inviato"
		else
			exit 1
		fi
		;;
		*)
		if [ $type = "private" ]; then
			number=$(( ( RANDOM % 500 )  + 1 ))
			if	[ $number = 69 ]
				then
				reply="Nice."
			elif	[ $number = 1 ]
				then
				reply="Sei il number uno"
			elif	[ $number -gt 250 ]
				then
				reply="Ok"
			elif	[ $number -lt 250 ]
				then
				reply="Alright"
			fi
			return_feedback=$reply
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
        "bin "*)
		admin=$(cat neekshelladmins | grep -v "#" | grep -w $inline_user_id)
		    if [ "x$admin" != "x" ]
			then
                	command="echo \$($(echo $update | jq -r ".inline_query.query" | sed -e 's/bin //'))"
                	command_result=$(eval $(echo "timeout 2s $(echo $command)") 2>&1 )
			return_query=$(inline_command)
			else
			return_query=$(inline_denied)
		    fi
        ;;
	"tag "*)
		usertag=$(echo $results | sed -Ee 's/(.* )(\[.*\]) ((.*))/\2/' -e 's/[[:punct:]]//g')
		usertext=$(echo $results | sed -Ee 's/(.* )(\[.*\]) ((.*))/\3/' -Ee 's/[[:punct:]](.*)[[:punct:]]/\1/')
		userid=$(cat ./neekshell_db/users/$(echo $usertag | sed 's/@//') | sed 's/\s.*$//')
		return_query=$(inline_tag)
	;;
        'search '*)
            offset=$(($(echo $update | jq -r ".inline_query.offset")+1))
            search=$(echo $results | sed 's/search //g')
            resnumber=$(googler --unfilter --json -n 5 -s $offset $search | jq -r ". | length")
            if [ $offset = 1 ]
                then
                nextpage=1
                else
                nextpage=$(($(echo $offset)+$(echo $resnumber)))
            fi
            googler_results=$(googler --unfilter --json -n 5 -s $nextpage $search)
			x=0
            return_query=$(inline_google)
        ;;
        'gel '*)
            el=0
            rig=1
            offset=$(($(echo $update | jq -r ".inline_query.offset")+1))
            tags=$(echo $results | sed 's/gel //g')
			wget --user-agent 'Mozilla/5.0' -qO - "https://gelbooru.com/index.php?page=dapi&s=post&pid=$offset&tags=$tags&q=index&limit=20&api_key=20169d287696c16948e85c8ee715241ea636662e7419186d21f3355b4432c5ba&user_id=455640" > tempgel
            thumblist=$(cat tempgel | sed -n 's/.*preview_url="\([^"]*\)".*/\1/p' | grep -E 'jpg|jpeg|png')
            piclist=$(cat tempgel | sed -n 's/.*sample_url="\([^"]*\)".*/\1/p' | grep -E 'jpg|jpeg|png')
            filelist=$(cat tempgel | sed -n 's/.*file_url="\([^"]*\)".*/\1/p' | grep -E 'jpg|jpeg|png')
            picnumber=$(cat tempgel | sed -n 's/.*sample_url="\([^"]*\)".*/\1/p' | grep -E -c 'jpg|jpeg|png')
            return_query=$(inline_booru)
            rm tempgel
        ;;
        'xb '*)
            el=0
            rig=1
            offset=$(($(echo $update | jq -r ".inline_query.offset")+1))
            tags=$(echo $results | sed 's/xb //g')
            wget --user-agent 'Mozilla/5.0' -qO - "https://xbooru.com/index.php?page=dapi&s=post&pid=$offset&tags=$tags&q=index&limit=20" > tempxb
            thumblist=$(cat tempxb | sed -n 's/.*preview_url="\([^"]*\)".*/\1/p' | grep -E 'jpg|jpeg|png')
            piclist=$(cat tempxb | sed -n 's/.*sample_url="\([^"]*\)".*/\1/p' | grep -E 'jpg|jpeg|png')
            filelist=$(cat tempxb | sed -n 's/.*file_url="\([^"]*\)".*/\1/p' | grep -E 'jpg|jpeg|png')
            picnumber=$(cat tempxb | sed -n 's/.*sample_url="\([^"]*\)".*/\1/p' | grep -E -c 'jpg|jpeg|png')
            return_query=$(inline_booru)
            rm tempxb
        ;;
        'xbgif '*)
            el=0
            rig=1
            offset=$(($(echo $update | jq -r ".inline_query.offset")+1))
            tags=$(echo $results | sed 's/xbgif //g')
            wget --user-agent 'Mozilla/5.0' -qO - "https://xbooru.com/index.php?page=dapi&s=post&pid=$offset&tags=gif+$tags&q=index&limit=20" > tempxbgif
            giflist=$(cat tempxbgif | sed -n 's/.*sample_url="\([^"]*\)".*/\1/p' | grep -E 'gif')
            filelist=$(cat tempxbgif | sed -n 's/.*file_url="\([^"]*\)".*/\1/p' | grep -E 'gif')
            gifnumber=$(cat tempxbgif | sed -n 's/.*sample_url="\([^"]*\)".*/\1/p' | grep -E -c 'gif')
            return_query=$(inline_boorugif)
            rm tempxbgif
        ;;
    esac
}

function process_reply() {
	update=$(cat ./tempinput)
    message_id=$(echo $update | jq -r ".message.reply_to_message.message_id")
    if [ "$message_id" = "null" ]; then
	    message_id=$(echo $update | jq -r ".message.message_id")
    fi
    normal_user=$(echo $update | jq -r ".message.from.username")
    username_id=$(echo $update | jq -r ".message.from.id")
    chat_id=$(echo $update | jq -r ".message.chat.id")
    inline_user=$(echo $update | jq -r ".inline_query.from.username")
    inline_user_id=$(echo $update | jq -r ".inline_query.from.id")
    inline_id=$(echo $update | jq -r ".inline_query.id")
    type=$(echo $update | jq -r ".message.chat.type")
	text=$(echo $update | jq -r ".message.text" | sed 's/"/\\&/g')
	results=$(echo $update | jq -r ".inline_query.query" | sed 's/"/\\&/g')
	# database id
	if [ -n $normal_user ]; then
		if [ ! -d ./neekshell_db/users/ ]; then
			mkdir -p ./neekshell_db/users/
		fi
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
	get_feedback_reply "$update"
    if      [ "$first_normal" != "null" ] && [ -n "$first_normal" ]
        then
            result=$(wget -q -O/dev/null --post-data "chat_id=$chat_id&reply_to_message_id=$message_id&parse_mode=html&text=$return_feedback" "${TELEAPI}/sendMessage")
    elif    [ "$results" != "null" ] && [ -n "$results" ]
        then
			result=$(wget -q -O/dev/null --post-data "inline_query_id=$inline_id&results=$return_query&next_offset=$offset&cache_time=100&is_personal=true" "${TELEAPI}/answerInlineQuery")
    fi
    if      [ "$first_normal" != "null" ] && [ -n "$first_normal" ] && [ "$type" = "private" ]
        then
                echo -e "\n--\nnormal=${text}\nfrom ${normal_user} at $(date "+%Y-%m-%d %H:%M")\n--"
        
    elif    [ "$results" != "null" ] && [ -n "$results" ]
        then
                echo -e "\n--\ninline=${results}\nfrom ${inline_user} at $(date "+%Y-%m-%d %H:%M")\n--"
    fi
    ## activate to log debug
    #echo -e ": forward=${forward}"
    #echo -e ": inline_query=${return_query}"
    #echo -e ": inline_message=${results}"
}
process_reply
