#!/bin/mksh
update_stats() {
	[[ ! -d stats/users-d ]] && mkdir -p stats/users-d || /bin/rm stats/users-d/*
	[[ ! -d stats/chats-d ]] && mkdir -p stats/chats-d || /bin/rm stats/chats-d/*
	/bin/mv stats/chats/* stats/chats-d/
	/bin/mv stats/users/* stats/users-d/
}
get_stats() {
	if [[ "$chat_id" != "" ]] || [[ "$user_id" != "" ]]; then
		if [[ "$s_target" == "users" ]]; then
			if [[ "$s_time" == "today" ]]; then
				usage=$(cat stats/users/"$user_id"-usage | cut -f 1 -d :)
				if [[ "$usage" != "" ]]; then
					text_id="Today usage in ms: $usage"
				fi
			else
				usage=$(cat stats/users-d/"$user_id"-usage | cut -f 1 -d :)
				if [[ "$usage" != "" ]]; then
					text_id="Yesterday usage in ms: $usage"
				fi
			fi
		else
			if [[ "$s_time" == "today" ]]; then
				usage=$(cat stats/chats/"$chat_id"-usage | cut -f 1 -d :)
				if [[ "$usage" != "" ]]; then
					text_id="Today total messages: $usage"
				fi
			else
				usage=$(cat stats/chats-d/"$chat_id"-usage | cut -f 1 -d :)
				if [[ "$usage" != "" ]]; then
					text_id="Yesterday total messages: $usage"
				fi
			fi
		fi
	fi
}
if [[ "$1" == "update" ]]; then
	update_stats
else
	get_stats
fi
