[[ "$1" = "" ]] && exit
enable_markdown=true
parse_mode=html
case "$subreddit" in
	none)
		case "$filter" in
			random)
				r_input=$(wget -q -O- "https://reddit.com/random/.json")
				hot=$(jshon -e 0 -e data -e children -e 0 -e data <<< "$r_input")
			;;
		esac
	;;
	"https"*)
		if [[ "$(grep "reddit.com" <<< "$subreddit")" != "" ]]; then
			if [[ "$(grep '?' <<< "$subreddit")" != "" ]]; then
				subreddit=$(sed 's/\?.*//' <<< "$subreddit")
			fi
			r_input=$(wget -q -O- "$subreddit/.json")
		else
			text_id="invalid link"
			get_reply_id any
			tg_method send_message > /dev/null
			return
		fi
		hot=$(jshon -e 0 -e data -e children -e 0 -e data <<< "$r_input")
	;;
	*)
		case "$filter" in
			random)
				r_input=$(wget -q -O- "https://reddit.com/r/${subreddit}/random/.json")
				hot=$(jshon -e 0 -e data -e children -e 0 -e data <<< "$r_input")
			;;
			*)
				amount=10
				r_input=$(wget -q -O- "https://reddit.com/r/${subreddit}/.json?sort=top&t=week&limit=$amount")
				hot=$(jshon -e data -e children -e $((RANDOM % $amount)) -e data <<< "$r_input")
				if [[ "$filter" = "pic" ]] \
				&& [[ "$(jshon -e url -u <<< "$hot" | grep "i.redd.it\|imgur" | grep "jpg\|png")" = "" ]]; then
					x=0
					while [[ "$s_pic" != "found" ]]; do
						hot=$(jshon -e data -e children -e $x -e data <<< "$r_input")
						pic=$(jshon -e url -u <<< "$hot" | grep "i.redd.it\|imgur" | grep "jpg\|png")
						x=$((x+1))
						if [[ "$pic" != "" ]]; then
							s_pic="found"
						fi
						if [[ $x -gt 10 ]]; then
							text_id="pic not found"
							tg_method send_message > /dev/null
							return
						fi
					done
				fi
			;;
		esac
	;;
esac
media_id=$(jshon -e url -u <<< "$hot" | grep "i.redd.it\|imgur\|gfycat\|redgifs")
video=$(jshon -Q -e secure_media -e reddit_video <<< "$hot")
permalink=$(jshon -e permalink -u <<< "$hot" | cut -f 5 -d /)
if [[ "$media_id" ]]; then
	if [[ "$(grep "gfycat\|redgifs" <<< "$media_id")" ]]; then
		media_id=$(wget -q -O- "$media_id" | sed -En 's|.*<source src="(https://thumbs.*mp4)" .*|\1|p')
	elif [[ "$(grep "gifv$" <<< "$media_id")" ]]; then
		media_id=$(sed 's/gifv$/mp4/' <<< "$media_id")
	fi
elif [[ "$video" ]]; then
	youtube-dl --quiet --no-warnings --merge-output-format mp4 -o "$permalink.mp4" "https://www.reddit.com/$permalink/"
fi
title=$(jshon -e title -u <<< "$hot")
stickied=$(jshon -e stickied -u <<< "$hot")
if [[ "$title" != "" ]]; then
	caption=$(printf '%s\n' \
		"$title" \
		"link: redd.it/$permalink")
fi
if [[ "$(grep "jpg\|png" <<< "$media_id")" != "" ]]; then
	photo_id=$media_id
	if [[ "$(tg_method send_photo | jshon -Q -e ok)" = "false" ]]; then
		text_id=$caption
		tg_method send_message
	fi
elif [[ "$(grep "gif" <<< "$media_id")" != "" ]]; then
	animation_id=$media_id
	if [[ "$(tg_method send_animation | jshon -Q -e ok)" = "false" ]]; then
		text_id=$caption
		tg_method send_message
	fi
elif [[ "$(grep "mp4" <<< "$media_id")" != "" ]] && [[ "$(ffprobe "$media_id" 2>&1 | grep -o 'Audio:')" = "" ]]; then
	animation_id=$media_id
	if [[ "$(tg_method send_animation | jshon -Q -e ok)" = "false" ]]; then
		text_id=$caption
		tg_method send_message
	fi
elif [[ "$(grep "mp4" <<< "$media_id")" != "" ]] && [[ "$(ffprobe "$media_id" 2>&1 | grep -o 'Audio:')" != "" ]]; then
	video_id=$media_id
	if [[ "$(tg_method send_video | jshon -Q -e ok)" = "false" ]]; then
		text_id=$caption
		tg_method send_message
	fi
elif [[ "$video" ]]; then
	video_id="@$permalink.mp4"
	tg_method send_video upload
	rm -f "$permalink.mp4"
else
	text_id=$caption
	tg_method send_message
fi
