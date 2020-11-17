case $callback_message_text in
	"Select chat to join:")
		chat_id=$callback_user_id
		if [ "$(grep -r "$callback_user_id" $bot_chat_dir)" = "" ]; then
			sed -i "s/\(users: \)/\1$callback_user_id /" $bot_chat_dir"$callback_data"
			button_text_reply="joined"
			text_id="joined $callback_data"
		else
			button_text_reply="you're already in an existing chat"
			text_id="you're already in an existing chat"
		fi
		tg_method button_reply > /dev/null
		tg_method send_message > /dev/null
	;;
	"Select chat to leave:")
		sed -i "s/$callback_user_id //" $bot_chat_dir"$callback_data"
		button_text_reply="bye"
		tg_method button_reply > /dev/null
		chat_id=$callback_user_id
		text_id="$callback_data is no more"
		tg_method send_message > /dev/null
	;;
	"selected directory: "*)
		button_text_reply="ok"
		tg_method button_reply > /dev/null
		document_id="@$(sed -n 1p <<< "$callback_message_text" | sed 's/^selected directory: //')/$callback_data"
		chat_id=$callback_user_id
		tg_method send_document > /dev/null
	;;
esac
