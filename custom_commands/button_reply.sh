case "$callback_message_text" in
	"Select chat to join:")
		chat_id=$callback_user_id
		if [[ "$(grep -r "$callback_user_id" $bot_chat_dir)" = "" ]]; then
			sed -i "s/\(users: \)/\1$callback_user_id /" $bot_chat_dir"$callback_data"
			button_text_reply="joined"
			text_id="joined $callback_data"
		else
			button_text_reply="you're already in an existing chat"
			text_id="you're already in an existing chat"
		fi
		tg_method button_reply
		tg_method send_message
	;;
	"Select chat to leave:")
		sed -i "s/$callback_user_id //" $bot_chat_dir"$callback_data"
		button_text_reply="bye"
		tg_method button_reply
		chat_id=$callback_user_id
		text_id="$callback_data is no more"
		tg_method send_message
	;;
	"selected directory: "*)
		button_text_reply="ok"
		tg_method button_reply
		selected_dir=$(sed -n 1p <<< "$callback_message_text" | sed 's/^selected directory: //')
		selected_file=$(dir -N1 --file-type -- "$selected_dir" | sed '/\/$/d' | sed -n ${callback_data}p)
		document_id="@$selected_dir/$selected_file"
		chat_id=$callback_user_id
		tg_method send_document upload
	;;
	"sleep")
		case "$callback_data" in
			delay)
				touch "$tmpdir/sleep_delay"
				button_text_reply=delayed
			;;
			cancel)
				touch "$tmpdir/sleep_cancel"
				button_text_reply=canceled
			;;
		esac
		tg_method button_reply
	;;
esac
case "$callback_data" in
	"insta "*)
		cd $tmpdir
		sign=$(cut -f 2 -d ' ' <<< "$callback_data")
		ig_tag=$(cut -f 3 -d ' ' <<< "$callback_data")
		chat_id=$(cut -f 4 -d ' ' <<< "$callback_data")
		request_id="${ig_tag}_${chat_id}"
		cd "$request_id"
		if [[ "$callback_user_id" != "$(cat ig_userid)" ]]; then
			return
		fi
		ig_page=$(($(cat ig_page) $sign 1))
		if [[ $ig_page -eq 1 ]]; then
			button_text=(">")
			button_data=("insta + $ig_tag $chat_id")
		elif [[ "$(sed -n $(($ig_page+1))p ig_list)" = "" ]]; then
			button_text=("<")
			button_data=("insta - $ig_tag $chat_id")
		else
			j=1
			button_text=("<" ">")
			button_data=("insta - $ig_tag $chat_id" "insta + $ig_tag $chat_id")
		fi
		printf '%s' "$ig_page" > ig_page
		markup_id=$(inline_array button)
		media_id="@$(sed -n ${ig_page}p ig_list)"
		to_delete_id=$(cat ig_id)
		tg_method button_reply
		cd "$ig_tag"
		tg_method delete_message
		ext=$(grep -o "...$" <<< "$media_id")
		case "$ext" in
			jpg)
				photo_id=$media_id
				tg_method send_photo upload
				ig_id=$(jshon -Q -e result -e message_id -u <<< "$curl_result")
			;;
			mp4)
				video_id=$media_id
				tg_method send_video upload
				ig_id=$(jshon -Q -e result -e message_id -u <<< "$curl_result")
			;;
		esac
		cd ..
		printf '%s' "$ig_id" > ig_id
		cd "$basedir"
	;;
esac
