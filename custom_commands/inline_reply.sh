case "$inline_message" in
	"fortune")
		fortune=$(/usr/bin/fortune fortunes paradoxum goedel linuxcookie | tr '\n' ' ' | awk '{$2=$2};1')
		title="Cookie"
		message_text=$(printf '%s\n' "Your fortune cookie states:" "$(/usr/bin/fortune fortunes paradoxum goedel linuxcookie | tr '\n' ' ' | awk '{$2=$2};1')")
		description="Open your fortune cookie"
		tg_method send_inline article
	;;
	d[0-9]*)
		title="Result of $inline_message"
		number=$(( ( RANDOM % $(sed 's/d//' <<< "$inline_message") )  + 1 ))
		message_text=$(printf '%s\n' "$title" "$number")
		tg_method send_inline article
	;;
	[Ff])
		button_text="F"
		button_data="F0"
		title="Press F to pay respects"
		message_text=$title
		tg_method send_inline article
	;;
	"figlet "*)
		figtext=$(sed 's/figlet //' <<< "$inline_message")
		markdown=("<code>" "</code>")
		parse_mode=html
		message_text=$(figlet -- "$figtext" | sed 's/\s*$//' | sed '/^$/d')
		title="figlet $figtext"
		tg_method send_inline article
	;;
	"booru "*)
		source tools/booru_api.sh
		offset=$(($(jshon -Q -e offset -u <<< "$inline")+1))
		tags=$(tr ' ' '+' <<< "$(sed 's/booru //' <<< "$inline_message")")
		website="gelbooru.com"
		booru_site="gelbooru"
		limit=5
		no_video="-video+-webm+-animated+-animated_gif+-animated_png"
		getbooru=$(curl -A 'Mozilla/5.0' -s "https://$website/index.php?page=dapi&s=post&json=1&pid=$offset&tags=$tags+$no_video&q=index&limit=$limit")
		booru_api # get n_posts
		for x in $(seq 0 $(($n_posts - 1))); do
			if [[ "$(booru_api has_sample)" ]]; then
				hash=$(booru_api hash)
				photo_url[$x]=$(booru_api sample)
				thumb_url[$x]=${photo_url[$x]}
			else
				photo_url[$x]=$(booru_api file)
				thumb_url[$x]=${photo_url[$x]}
			fi
			photo_width[$x]=$(booru_api width)
			photo_height[$x]=$(booru_api height)
			caption[$x]="source: https://$website/index.php?page=post&s=view&id=$(booru_api id)"
		done
		tg_method send_inline photo
	;;
	"search "*)
		offset=$(($(jshon -Q -e offset -u <<< "$inline")+1))
		search=$(sed 's/search //' <<< "$inline_message" | sed 's/\s/%20/g')
		searx_results=$(wget -q -O- "https://archneek.zapto.org/searx/?q=$search&pageno=$offset&categories=general&format=json")
		for j in $(seq 0 $(($(jshon -Q -e results -l <<< "$searx_results")-1)) ); do
			title[$j]=$(jshon -Q -e results -e "$j" -e title -u <<< "$searx_results")
			url[$j]=$(jshon -Q -e results -e "$j" -e url -u <<< "$searx_results")
			message_text[$j]=$(printf '%s\n' "${title[$j]}" "${url[$j]}")
			description[$j]=$(jshon -Q -e results -e "$j" -e content -u <<< "$searx_results")
		done
		tg_method send_inline article
	;;
	"invite")
		if [[ $(is_status admins) ]]; then
			join_id="917684979"
			button_text="click to join"
			button_url="http://t.me/neekshellbot?start=join$join_id"
			title="anonymous group chat"
			message_text="anonymous group chat"
			tg_method send_inline article
		fi
	;;
	*" bin")
		if [[ $(is_status admins) ]]; then
			command=$(sed 's/ bin$//' <<< "$inline_message")
			markdown=("<code>" "</code>")
			parse_mode=html
			message_text=$(printf '%s\n' "$ $command" "$(mksh -c "$command" 2>&1)")
			title=$command
			tg_method send_inline article
		fi
	;;
	*)
		owoarray=("owo" "ewe" "uwu" ":3" "x3" "🥵" "🙈" "🤣" "😘" "🥺" "💁‍♀️" "OwO" "😳" "🤠" "🤪" "😜" "🤬" "🤧" "🦹‍♂" "🍌" "😏" "😒" "😎" "🙄" "🧐" "😈" "👐🏻" "👏🏻" "👀" "👅" "🍆" "🤢" "🤮" "🤡" "💯" "👌" "😂" "🅱️" "💦")
		numberspace=$(tr -dc ' ' <<< "$reply" | wc -c)
		[[ "$numberspace" -eq "0" ]] && reply="$reply " && numberspace=1
		for x in $(seq $(((numberspace / 16)+1))); do
			inline_message=$(sed "s/\s/ ${owoarray[$((RANDOM % ${#owoarray[@]}))]} /$(((RANDOM % numberspace)+1))" <<< "$inline_message")
		done
		title=$(sed -e 's/[lr]/w/g' -e 's/[LR]/W/g' <<< "$inline_message")
		message_text=$title
		tg_method send_inline article
	;;
esac
