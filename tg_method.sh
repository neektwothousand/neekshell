tg_method() {
	if [[ "$parse_mode" = "html" ]]; then
		if [[ "$enable_markdown" = "" ]]; then
			text_id="${markdown[0]}$(sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g' <<< "$text_id")${markdown[1]}"
			caption="${markdown[0]}$(sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g' <<< "$caption")${markdown[1]}"
		fi
	fi
	case $2 in
		upload)
			curl_f="-F"
			header="-H 'Content-Type: multipart/form-data'"
		;;
		*)
			curl_f="--form-string"
			header="-H 'Content-Type: application/json'"
		;;
	esac
	curl_result=$(case $1 in
		send_message)
			curl -s "${TELEAPI}/sendMessage" \
				$curl_f "chat_id=$chat_id" \
				$curl_f "parse_mode=$parse_mode" \
				$curl_f "reply_to_message_id=$reply_id" \
				$curl_f "reply_markup=$markup_id" \
				$curl_f "text=$text_id"
		;;
		send_photo)
			curl -s "${TELEAPI}/sendPhoto" \
				$curl_f "chat_id=$chat_id" \
				$curl_f "parse_mode=$parse_mode" \
				$curl_f "reply_to_message_id=$reply_id" \
				$curl_f "reply_markup=$markup_id" \
				$curl_f "caption=$caption" \
				$curl_f "photo=$photo_id"
		;;
		send_document)
			curl -s "${TELEAPI}/sendDocument" \
				$curl_f "chat_id=$chat_id" \
				$curl_f "parse_mode=$parse_mode" \
				$curl_f "reply_to_message_id=$reply_id" \
				$curl_f "caption=$caption" \
				$curl_f "document=$document_id"
		;;
		send_video)
			if [[ "$2" == "upload" ]]; then
				video_info=$(ffprobe -v error -show_entries stream=width,height -of default=noprint_wrappers=1 "${video_id/@/}")
				width=$(sed -n 's/^width=//p' <<< "$video_info")
				height=$(sed -n 's/^height=//p' <<< "$video_info")
				ffmpeg -i "${video_id/@/}" -ss 01 -frames:v 1 -vf scale=320:-1 "${thumb/@/}"
			fi
			curl -s "$TELEAPI/sendVideo" \
				$curl_f "chat_id=$chat_id" \
				$curl_f "parse_mode=$parse_mode" \
				$curl_f "reply_to_message_id=$reply_id" \
				$curl_f "reply_markup=$markup_id" \
				$curl_f "thumb=$thumb" \
				$curl_f "supports_streaming=true" \
				$curl_f "width=$width" \
				$curl_f "height=$height" \
				$curl_f "caption=$caption" \
				$curl_f "video=$video_id"
		;;
		send_mediagroup)
			curl -s "$TELEAPI/sendMediaGroup" \
				$curl_f "chat_id=$chat_id" \
				$curl_f "reply_to_message_id=$reply_id" \
				$curl_f "media=$mediagroup_id"
		;;
		send_audio)
			curl -s "$TELEAPI/sendAudio" \
				$curl_f "chat_id=$chat_id" \
				$curl_f "parse_mode=$parse_mode" \
				$curl_f "reply_to_message_id=$reply_id" \
				$curl_f "caption=$caption" \
				$curl_f "audio=$audio_id"
		;;
		send_voice)
			curl -s "$TELEAPI/sendVoice" \
				$curl_f "chat_id=$chat_id" \
				$curl_f "parse_mode=$parse_mode" \
				$curl_f "reply_to_message_id=$reply_id" \
				$curl_f "caption=$caption" \
				$curl_f "voice=$voice_id"
		;;
		send_animation)
			curl -s "$TELEAPI/sendAnimation" \
				$curl_f "chat_id=$chat_id" \
				$curl_f "parse_mode=$parse_mode" \
				$curl_f "reply_to_message_id=$reply_id" \
				$curl_f "reply_markup=$markup_id" \
				$curl_f "caption=$caption" \
				$curl_f "animation=$animation_id"
		;;
		send_sticker)
			curl -s "$TELEAPI/sendSticker" \
				$curl_f "chat_id=$chat_id" \
				$curl_f "parse_mode=$parse_mode" \
				$curl_f "reply_to_message_id=$reply_id" \
				$curl_f "caption=$caption" \
				$curl_f "sticker=$sticker_id"
		;;
		send_inline)
			curl -s "$TELEAPI/answerInlineQuery" \
				$curl_f "inline_query_id=$inline_id" \
				$curl_f "results=$return_query" \
				$curl_f "next_offset=$offset" \
				$curl_f "cache_time=0" \
				$curl_f "is_personal=true"
		;;
		forward_message)
			curl -s "$TELEAPI/forwardMessage" \
				$curl_f "chat_id=$chat_id" \
				$curl_f "from_chat_id=$from_chat_id" \
				$curl_f "message_id=$forward_id"
		;;
		inline_reply)
			curl -s "$TELEAPI/answerInlineQuery" \
				$curl_f "inline_query_id=$inline_id" \
				$curl_f "results=$return_query" \
				$curl_f "next_offset=$offset" \
				$curl_f "cache_time=100" \
				$curl_f "is_personal=true"
		;;
		button_reply)
			curl -s "$TELEAPI/answerCallbackQuery" \
				$curl_f "callback_query_id=$callback_id" \
				$curl_f "text=$button_text_reply"
		;;
		edit_text)
			curl -s "$TELEAPI/editMessageText" \
				$curl_f "chat_id=$chat_id" \
				$curl_f "message_id=$edit_id" \
				$curl_f "parse_mode=$parse_mode" \
				$curl_f "text=$edit_text"
		;;
		edit_media)
			curl -s "$TELEAPI/editMessageMedia" \
				-d "$(printf '%s' \
					"{\"chat_id\":\"$chat_id\"," \
					"\"message_id\":\"$edit_id\"," \
						"\"media\":{" \
							"\"type\":\"$edit_type\"," \
							"\"media\":\"$edit_media\"" \
						"}," \
					"\"reply_markup\":\"$markup_id\""\
					"}")" \
				-H 'Content-Type: application/json'
		;;
		edit_reply_markup)
			curl -s "$TELEAPI/editMessageReplyMarkup" \
				$curl_f "inline_message_id=$inline_message_id" \
				$curl_f "reply_markup=$markup_id"
		;;
		delete_message)
			curl -s "$TELEAPI/deleteMessage" \
				$curl_f "chat_id=$chat_id" \
				$curl_f "message_id=$to_delete_id"
		;;
		copy_message)
			curl -s "$TELEAPI/copyMessage" \
				$curl_f "chat_id=$chat_id" \
				$curl_f "from_chat_id=$from_chat_id" \
				$curl_f "message_id=$copy_id"
		;;
		set_chat_permissions)
			curl -s "$TELEAPI/setChatPermissions" \
				-d "$(printf '%s' \
					"{\"chat_id\":\"$chat_id\"," \
					"\"permissions\":{" \
					"\"can_send_messages\":$can_send_messages," \
					"\"can_send_media_messages\":$can_send_media_messages," \
					"\"can_send_other_messages\":$can_send_other_messages," \
					"\"can_send_polls\":$can_send_polls," \
					"\"can_add_web_page_previews\":$can_add_web_page_previews}}")" \
				-H 'Content-Type: application/json'
		;;
		restrict_member)
			curl -s "$TELEAPI/restrictChatMember" \
				-d "$(printf '%s' \
					"{\"chat_id\":\"$chat_id\"," \
					"\"user_id\":$restrict_id," \
					"\"permissions\":{" \
					"\"can_send_messages\":$can_send_messages," \
					"\"can_send_media_messages\":$can_send_media_messages," \
					"\"can_send_other_messages\":$can_send_other_messages," \
					"\"can_send_polls\":$can_send_polls," \
					"\"can_add_web_page_previews\":$can_add_web_page_previews}}")" \
				-H 'Content-Type: application/json'
		;;
		ban_member)
			curl -s "$TELEAPI/banChatMember" \
				$curl_f "chat_id=$chat_id" \
				$curl_f "user_id=$ban_id"
		;;
		unban_member)
			curl -s "$TELEAPI/unbanChatMember" \
				$curl_f "chat_id=$chat_id" \
				$curl_f "user_id=$unban_id" \
				$curl_f "only_if_banned=true"
		;;
		leave_chat)
			curl -s "$TELEAPI/leaveChat" \
				$curl_f "chat_id=$chat_id"
		;;
		get_chat)
			curl -s "$TELEAPI/getChat" \
				$curl_f "chat_id=$get_chat_id"
		;;
		get_chat_member)
			curl -s "$TELEAPI/getChatMember" \
				$curl_f "chat_id=$chat_id" \
				$curl_f "user_id=$get_member_id"
		;;
		get_me)
			curl -s "$TELEAPI/getMe"
		;;
	esac)
	if [[ "$(jshon -Q -e parameters -e retry_after -u <<< "$curl_result")" != "" ]]; then
		retry_after=$(jshon -Q -e parameters -e retry_after -u <<< "$curl_result")
		sleep "$retry_after"
		tg_method $@
	elif [[ "$(jshon -Q -e ok -u <<< "$curl_result")" == "false" ]]; then
		printf '%s\n' "$chat_id:" "$curl_result" >> method_error.log
	fi
}
