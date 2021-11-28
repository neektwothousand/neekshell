case "$inline_user_id" in
	160551211) # neek
		case "$inline_message" in
			"markov")
				cd misc-shell/markov/
				rand_messages=$(( ($(cat /dev/urandom | tr -dc '[:digit:]' 2>/dev/null | head -c 6) % 240000) + 1 ))
				sed -n ${rand_messages},$((rand_messages + 4999))p recupero_text_full > recupero_text
				markov_results=$(./markupero.py | grep -v '^None$')
				while [[ "$markov_results" = "" ]] && [[ "$x" -le 5 ]]; do
					x=$((x+1))
					rand_messages=$(( ($(cat /dev/urandom | tr -dc '[:digit:]' 2>/dev/null | head -c 6) % 240000) + 1 ))
					sed -n ${rand_messages},$((rand_messages + 4999))p recupero_text_full > recupero_text
					markov_results=$(./markupero.py | grep -v '^None$')
				done
				if [[ "$markov_results" = "" ]]; then
					message_text="error"
					title="error"
					return_query=$(json_array inline article)
					tg_method send_inline > /dev/null
					return
				fi
				for j in $(seq 0 $(($(wc -l <<< "$markov_results")-1))); do
					message_text[$j]=$(sed -n $((j+1))p <<< "$markov_results")
					title[$j]=$((j+1))
					description[$j]=${message_text[$j]}
				done
				return_query=$(json_array inline article)
				tg_method send_inline > /dev/null
				return
			;;
		esac
	;;
esac
case "$inline_message" in
	"fortune")
		fortune=$(/usr/bin/fortune fortunes paradoxum goedel linuxcookie | tr '\n' ' ' | awk '{$2=$2};1')
		title="Cookie"
		message_text=$(printf '%s\n' "Your fortune cookie states:" "$(/usr/bin/fortune fortunes paradoxum goedel linuxcookie | tr '\n' ' ' | awk '{$2=$2};1')")
		description="Open your fortune cookie"
		return_query=$(json_array inline article)
		tg_method send_inline > /dev/null
	;;
	d[0-9]*)
		title="Result of $inline_message"
		number=$(( ( RANDOM % $(sed 's/d//' <<< "$inline_message") )  + 1 ))
		message_text=$(printf '%s\n' "$title" "$number")
		return_query=$(json_array inline article)
		tg_method send_inline > /dev/null
	;;
	[Ff])
		button_text="F"
		button_data="F0"
		markup_id=$(json_array inline button)
		title="Press F to pay respects"
		message_text=$title
		return_query=$(json_array inline article)
		tg_method send_inline
	;;
	"figlet "*)
		figtext=$(sed 's/figlet //' <<< "$inline_message")
		markdown=("<code>" "</code>")
		parse_mode=html
		message_text=$(figlet -- "$figtext" | sed 's/\s*$//' | sed '/^$/d')
		title="figlet $figtext"
		return_query=$(json_array inline article)
		tg_method send_inline > /dev/null
	;;
	"jafw "*)
		j_normal=$(sed -e "s/jafw //" -e "s/ /  /g" <<< "$inline_message")
		j_fullw_low=$(sed -e 's/a/ａ/g' -e 's/b/ｂ/g' -e 's/c/ｃ/g' -e 's/d/ｄ/g' -e 's/e/ｅ/g' -e 's/f/ｆ/g' -e 's/g/ｇ/g' -e 's/h/ｈ/g' -e 's/i/ｉ/g' -e 's/j/ｊ/g' -e 's/k/ｋ/g' -e 's/l/ｌ/g' -e 's/m/ｍ/g' -e 's/n/ｎ/g' -e 's/o/ｏ/g' -e 's/p/ｐ/g' -e 's/q/ｑ/g' -e 's/r/ｒ/g' -e 's/s/ｓ/g' -e 's/t/ｔ/g' -e 's/u/ｕ/g' -e 's/v/ｖ/g' -e 's/w/ｗ/g' -e 's/x/ｘ/g' -e 's/y/ｙ/g' -e 's/z/ｚ/g' <<< "$j_normal")
		j_fullw=$(sed -e 's/A/Ａ/g' -e 's/B/Ｂ/g' -e 's/C/Ｃ/g' -e 's/D/Ｄ/g' -e 's/E/Ｅ/g' -e 's/F/Ｆ/g' -e 's/G/Ｇ/g' -e 's/H/Ｈ/g' -e 's/I/Ｉ/g' -e 's/J/Ｊ/g' -e 's/K/Ｋ/g' -e 's/L/Ｌ/g' -e 's/M/Ｍ/g' -e 's/N/Ｎ/g' -e 's/O/Ｏ/g' -e 's/P/Ｐ/g' -e 's/Q/Ｑ/g' -e 's/R/Ｒ/g' -e 's/S/Ｓ/g' -e 's/T/Ｔ/g' -e 's/U/Ｕ/g' -e 's/V/Ｖ/g' -e 's/W/Ｗ/g' -e 's/X/Ｘ/g' -e 's/Y/Ｙ/g' -e 's/Z/Ｚ/g' <<< "$j_fullw_low")
		j_trans=$(trans :ja -j -b "$j_normal")
		title="『 $j_trans — $j_fullw 』"
		message_text=$title
		return_query=$(json_array inline article)
		tg_method send_inline > /dev/null
	;;
	"booru "*)
		offset=$(($(jshon -Q -e offset -u <<< "$inline")+1))
		tags=$(tr ' ' '+' <<< "$(sed 's/booru //' <<< "$inline_message")")
		website="gelbooru.com"
		booru_site="gelbooru"
		limit=5 y=0
		no_video="-video+-webm+-animated+-animated_gif+-animated_png"
		getbooru=$(curl -A 'Mozilla/5.0' -s "https://$website/index.php?page=dapi&s=post&json=1&pid=$offset&tags=$tags+$no_video&q=index&limit=$limit")
		for j in $(seq 0 $((limit - 1))); do
			while [[ "$(grep "jpg$\|jpeg$\|png$" <<< "${photo_url[$j]}")" == "" ]]; do
				y=$((y+1))
				if [[ "$y" -gt "10" ]]; then
					break
				fi
				if [[ "$(jshon -Q -e $y -e sample -u <<< "$getbooru")" != "0" ]]; then
					hash=$(jshon -Q -e $y -e hash -u <<< "$getbooru")
					booru_dir=$(jshon -Q -e $y -e directory -u <<< "$getbooru")
					photo_url[$j]="https://$website/samples/$booru_dir/sample_$hash.jpg"
				else
					photo_url[$j]=$(jshon -Q -e $y -e file_url -u <<< "$getbooru")
				fi
				photo_width[$j]=$(jshon -Q -e $y -e width -u <<< "$getbooru")
				photo_height[$j]=$(jshon -Q -e $y -e height -u <<< "$getbooru")
			done
			thumb_url[$j]=${photo_url[$j]}
			caption[$j]="source: https://$website/index.php?page=post&s=view&id=$(jshon -Q -e $y -e id -u <<< "$getbooru")"
			y=$((y+1))
		done
		return_query=$(json_array inline photo)
		tg_method send_inline
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
		return_query=$(json_array inline article)
		tg_method send_inline > /dev/null
	;;
	"invite")
		if [[ $(is_admin) ]]; then
			join_id="917684979"
			button_text="click to join"
			button_url="http://t.me/neekshellbot?start=join$join_id"
			markup_id=$(json_array inline button)
			title="anonymous group chat"
			message_text="anonymous group chat"
			return_query=$(json_array inline article)
			tg_method send_inline
		fi
	;;
	*" bin")
		if [[ $(is_admin) ]]; then
			command=$(sed 's/ bin$//' <<< "$inline_message")
			markdown=("<code>" "</code>")
			parse_mode=html
			message_text=$(printf '%s\n' "$ $command" "$(mksh -c "$command" 2>&1)")
			title=$command
			return_query=$(json_array inline article)
			tg_method send_inline
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
		return_query=$(json_array inline article)
		tg_method send_inline
	;;
esac
