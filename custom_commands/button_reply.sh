case "$callback_message_text" in
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
case "$callback_data" in
	"insta "*)
		set -x
		cd $tmpdir
		sign=$(cut -f 2 -d ' ' <<< "$callback_data")
		ig_tag=$(cut -f 3 -d ' ' <<< "$callback_data")
		chat_id=$(cut -f 4 -d ' ' <<< "$callback_data")
		request_id="${ig_tag}_${chat_id}"
		cd "$request_id"
		ig_page=$(($(cat ig_page) $sign 1))
		if [ $ig_page -eq 1 ]; then
			button_text=(">")
			button_data=("insta + $ig_tag $chat_id")
		else
			j=1
			button_text=("<" ">")
			button_data=("insta - $ig_tag $chat_id" "insta + $ig_tag $chat_id")
		fi
		printf '%s' "$ig_page" > ig_page
		markup_id=$(inline_array button)
		media_id="@$(sed -n ${ig_page}p ig_list)"
		to_delete_id=$(cat ig_id)
		tg_method button_reply > /dev/null
		cd "$ig_tag"
		tg_method delete_message > /dev/null
		ext=$(grep -o "...$" <<< "$media_id")
		case "$ext" in
			jpg)
				photo_id=$media_id
				ig_id=$(tg_method send_photo upload | jshon -Q -e result -e message_id -u)
			;;
			mp4)
				video_id=$media_id
				ig_id=$(tg_method send_video upload | jshon -Q -e result -e message_id -u)
			;;
		esac
		cd ..
		printf '%s' "$ig_id" > ig_id
		set +x
	;;
esac
