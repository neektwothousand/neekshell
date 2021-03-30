#!/bin/mksh
if [[ "$chat_id" != "" ]] || [[ "$user_id" != "" ]]; then
	if [[ "$s_target" == "users" ]]; then
		if [[ "$s_time" == "today" ]]; then
			usage=$(grep -w -- "$(date +%y%m%d):$user_id" stats/users-usage | cut -f 3 -d :)
			if [[ "$usage" != "" ]]; then
				text_id="Today usage in ms: $usage"
			fi
		else
			usage=$(grep -w -- "$(date +%y%m%d -d "yesterday"):$user_id" stats/users-usage | cut -f 3 -d :)
			if [[ "$usage" != "" ]]; then
				text_id="Yesterday usage in ms: $usage"
			fi
		fi
	else
		if [[ "$s_time" == "today" ]]; then
			usage=$(grep -w -- "$(date +%y%m%d):$chat_id" stats/chats-usage | cut -f 3 -d :)
			if [[ "$usage" != "" ]]; then
				text_id="Today total messages: $usage"
			fi
		else
			usage=$(grep -w -- "$(date +%y%m%d -d "yesterday"):$chat_id" stats/chats-usage | cut -f 3 -d :)
			if [[ "$usage" != "" ]]; then
				text_id="Yesterday total messages: $usage"
			fi
		fi
	fi
fi
