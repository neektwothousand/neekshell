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
		pref="eJx1VUHP2zYM_TXzxUixroeechg2DCsw4Cuar7satMTInCXRpeTkc3_9KMdO7Kw7xAEp8ZF8epQMZHQshOnoMKKArzxEN4LDI8bD11Pl2YAvRgVjZsNh8Jjx6Jidx4qC7mwG4bfp-Af4hFXA3LE9fn45vVYJzpgQxHTHn6vcYcAjJwNSCabR59RwbCJemwztEm2ZGl1kf0E5Mqj5jsVVc9Qh5Ukr8ezIsMXLwYL0FdgLRIO2WRItOJSg9erF6Chqd5n7iTOnjnuITRPGROanX37z3KaM7yQ1DWW1z4JYJz7nKwjWlgRNZpmWVTOKYDRqLmSp70o9abGJ8s5tR4tx57CutnimSJk4pu0SxQtZ4jE96opDWHIW_G8jZ9xGhClg0LrqLBCT10O02-U4ATywWsrtaHrMC-KNqEJhXT6L9_2HDx_fmkYrQU5qD4iSxxY3rrlVnsqJ7wkoHYH8h5aWud81aow55MsGUcZ2chhW9lH4SnZPo-nLz3E9S63snP91zVH20C6hHbQC5bPYNwruiSbn9Bz18PKun3ZXs6C1pBtUknMMdMzbdczMfteQQ9TmA64NRFAp7CDHoDLc5HTkVJiQ8jNZJek99VrJo9d53OrBw1QHvlDJeMekuG3VkzKh0ijwidKPGkxsCHwd0BKoe4xJgVO3yZfwe4Two9iH5_3bLiBAzGTqZDr2oCQkQzor-ET-KkpLJn_nuFNSkaXOUk3_Nx33HnsyPaTNvDyN930j5ilw9LRPdBaKPYHZ1F-OIPEoZrfxnucO-O0KMe-xIEDhfB2kwP-oKnay1ylrUdxOmrfMFcb9PfUQ_BZBL0SyC4dazZn8XPQNabW2NK--sxUuE7XaTzyt7pRB8vA02FvNwTBs8vKAUXDgjevO1OqAoa8DibAsvsedPPhRm03HvykcPPXYdJx7nErUiyI3vxqDCvX7yyd9C65CuYjoU5zvTlRdCXt_J24FO823WnlRzO1Nm_RF8Hp9a-yfRdy3jWq9CuhtKM3XL38pvk4TStnz-vr5tMl3Qn9uNClLgPnGrpQ71ET_AqgHuKo="
		searx_results=$(curl -sL "https://archneek.zapto.org/searx/?preferences=$pref&q=$search&pageno=$offset&categories=general&language=en-US&format=json")
		nr=$(jshon -Q -e results -l <<< "$searx_results")
		for j in $(seq 0 $(($nr-1))); do
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
