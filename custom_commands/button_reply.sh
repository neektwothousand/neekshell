case "$callback_message_text" in
	"Select chat to join:")
		chat_id=$user_id
		if [[ "$(grep -r "$user_id" $bot_chat_dir)" = "" ]]; then
			sed -i "s/\(users: \)/\1$user_id /" $bot_chat_dir"$callback_data"
			button_text_reply="joined"
			text_id="joined $callback_data"
		else
			button_text_reply="you're already in an existing chat"
			text_id="you're already in an existing chat"
		fi
		tg_method send_message
	;;
	"Select chat to leave:")
		sed -i "s/$user_id //" $bot_chat_dir"$callback_data"
		button_text_reply="bye"
		chat_id=$user_id
		text_id="$callback_data is no more"
		tg_method send_message
	;;
esac
case "$callback_data" in
	"F"*)
		f=$((${callback_data/F/} + 1))
		button_text="F ($f)"
		button_data="F$f"
		tg_method edit_reply_markup
		button_text_reply="F"
	;;
esac
tg_method button_reply
