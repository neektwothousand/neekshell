case "$inline_user_id" in
	160551211) # neek
		case "$inline_message" in
			"markov")
				set -x
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
					return_query=$(inline_array article)
					tg_method send_inline > /dev/null
					return
				fi
				for j in $(seq 0 $(($(wc -l <<< "$markov_results")-1))); do
					message_text[$j]=$(sed -n $((j+1))p <<< "$markov_results")
					title[$j]=$((j+1))
					description[$j]=${message_text[$j]}
				done
				return_query=$(inline_array article)
				tg_method send_inline > /dev/null
				return
				set +x
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
		return_query=$(inline_array article)
		tg_method send_inline > /dev/null
	;;
	d[0-9]*)
		title="Result of $inline_message"
		number=$(( ( RANDOM % $(sed 's/d//' <<< "$inline_message") )  + 1 ))
		message_text=$(printf '%s\n' "$title" "$number")
		return_query=$(inline_array article)
		tg_method send_inline > /dev/null
	;;
	"figlet "*)
		figtext=$(sed 's/figlet //' <<< "$inline_message")
		markdown=("<code>" "</code>")
		parse_mode=html
		message_text=$(figlet -- "$figtext")
		title="figlet $figtext"
		return_query=$(inline_array article)
		tg_method send_inline > /dev/null
	;;
	"jafw "*)
		j_normal=$(sed -e "s/jafw //" -e "s/ /  /g" <<< "$inline_message")
		j_fullw_low=$(sed -e 's/a/ａ/g' -e 's/b/ｂ/g' -e 's/c/ｃ/g' -e 's/d/ｄ/g' -e 's/e/ｅ/g' -e 's/f/ｆ/g' -e 's/g/ｇ/g' -e 's/h/ｈ/g' -e 's/i/ｉ/g' -e 's/j/ｊ/g' -e 's/k/ｋ/g' -e 's/l/ｌ/g' -e 's/m/ｍ/g' -e 's/n/ｎ/g' -e 's/o/ｏ/g' -e 's/p/ｐ/g' -e 's/q/ｑ/g' -e 's/r/ｒ/g' -e 's/s/ｓ/g' -e 's/t/ｔ/g' -e 's/u/ｕ/g' -e 's/v/ｖ/g' -e 's/w/ｗ/g' -e 's/x/ｘ/g' -e 's/y/ｙ/g' -e 's/z/ｚ/g' <<< "$j_normal")
		j_fullw=$(sed -e 's/A/Ａ/g' -e 's/B/Ｂ/g' -e 's/C/Ｃ/g' -e 's/D/Ｄ/g' -e 's/E/Ｅ/g' -e 's/F/Ｆ/g' -e 's/G/Ｇ/g' -e 's/H/Ｈ/g' -e 's/I/Ｉ/g' -e 's/J/Ｊ/g' -e 's/K/Ｋ/g' -e 's/L/Ｌ/g' -e 's/M/Ｍ/g' -e 's/N/Ｎ/g' -e 's/O/Ｏ/g' -e 's/P/Ｐ/g' -e 's/Q/Ｑ/g' -e 's/R/Ｒ/g' -e 's/S/Ｓ/g' -e 's/T/Ｔ/g' -e 's/U/Ｕ/g' -e 's/V/Ｖ/g' -e 's/W/Ｗ/g' -e 's/X/Ｘ/g' -e 's/Y/Ｙ/g' -e 's/Z/Ｚ/g' <<< "$j_fullw_low")
		j_trans=$(trans :ja -j -b "$j_normal")
		title="『 $j_trans — $j_fullw 』"
		message_text=$title
		return_query=$(inline_array article)
		tg_method send_inline > /dev/null
	;;
	"booru "*)
		offset=$(($(jshon -Q -e offset -u <<< "$inline")+1))
		booru_prefix=$(cut -f 2 -d ' ' <<< "$inline_message")
		case "$booru_prefix" in
			'e621b'|'e621bgif')
				booru="e621.net"
				ilb="e621"
				tags=$(cut -f 3- -d ' ' <<< "$inline_message")
			;;
			'sb'|'sbgif')
				booru="safebooru.donmai.us"
				ilb="s"
				tags=$(cut -f 3- -d ' ' <<< "$inline_message")
			;;
			*)
				booru="gelbooru.com"
				ilb="g"
				tags=$(cut -f 2- -d ' ' <<< "$inline_message")
			;;
		esac
		limit=5 y=0
		case "$ilb" in 
			"e621")
				apikey=$(cat e621_api_key)
				getbooru=$(curl -A 'neekmkshbot/1.0 (by neek)' -s "https://e621.net/posts.json?tags=$tags&page=$offset&limit=$limit&$apikey")
				for j in $(seq 0 $((limit - 1))); do
					photo_url[$j]=$(jshon -Q -e posts -e $y -e file -e url -u <<< "$getbooru")
					while [[ "$(grep 'jpg\|jpeg' <<< "${photo_url[$j]}")" = "" ]]; do
						y=$((y+1))
						if [[ "$y" -gt "10" ]]; then
							break
						fi
						photo_url[$j]=$(jshon -Q -e posts -e $y -e file -e url -u <<< "$getbooru")
						photo_weight[$j]=$(curl -s -L -I "${photo_url[$j]}" | gawk -v IGNORECASE=1 '/^Content-Length/ { print $2 }')
						if [[ "${photo_weight[$j]}" -gt "5000000" ]]; then
							photo_url[$j]=""
						fi
					done
					thumb_url[$j]=${photo_url[$j]}
					caption[$j]="source: ${photo_url[$j]}"
					y=$((y+1))
				done
			;;
			*)
				case "$ilb" in
				"s")
					getbooru=$(wget -q -O- "https://$booru/posts.json?search[name_matches]=$tags&limit=$limit&page=$offset")
				;;
				*)
					getbooru=$(curl -A 'Mozilla/5.0' -s "https://$booru/index.php?page=dapi&s=post&json=1&pid=$offset&tags=$tags&q=index&limit=$limit")
				;;
				esac
				for j in $(seq 0 $((limit - 1))); do
					photo_url[$j]=$(jshon -Q -e $y -e file_url -u <<< "$getbooru")
					while [[ "$(grep 'jpg\|jpeg' <<< "${photo_url[$j]}")" = "" ]]; do
						y=$((y+1))
						if [[ "$y" -gt "10" ]]; then
							break
						fi
						photo_url[$j]=$(jshon -Q -e $y -e file_url -u <<< "$getbooru")
						photo_weight[$j]=$(curl -s -L -I "${photo_url[$j]}" | gawk -v IGNORECASE=1 '/^Content-Length/ { print $2 }')
						if [[ "${photo_weight[$j]}" -gt "5000000" ]]; then
							photo_url[$j]=""
						fi
					done
					thumb_url[$j]=${photo_url[$j]}
					caption[$j]="source: ${photo_url[$j]}"
					y=$((y+1))
				done
			;;
		esac
		return_query=$(inline_array photo)
		tg_method send_inline > /dev/null
	;;
	"search "*)
		offset=$(($(jshon -Q -e offset -u <<< "$inline")+1))
		search=$(sed 's/search //' <<< "$inline_message" | sed 's/\s/%20/g')
		searx_results=$(curl -s "https://archneek.zapto.org/searx/?q=$search&pageno=$offset&categories=general&format=json")
		for j in $(seq 0 $(($(jshon -Q -e results -l <<< "$searx_results")-1)) ); do
			title[$j]=$(jshon -Q -e results -e "$j" -e title -u <<< "$searx_results" | sed 's/"/\\"/g')
			url[$j]=$(jshon -Q -e results -e "$j" -e url -u <<< "$searx_results" | sed 's/"/\\"/g')
			message_text[$j]="${title[$j]}\\n${url[$j]}"
			description[$j]=$(jshon -Q -e results -e "$j" -e content -u <<< "$searx_results" | sed 's/"/\\"/g')
		done
		return_query=$(inline_array article)
		tg_method send_inline > /dev/null
	;;
	"arch "*)
		wiki_link="https://wiki.archlinux.org/index.php/$im_arg"
		wiki=$(curl -s "$wiki_link")
		title=$im_arg
		extract=$(grep -m 3 '<p>' <<< "$wiki" | grep -v 'a id="logo"\|<p>Related articles</p>' | head -n 1 | sed -e 's|>|&\n|g' | grep -v '^<' | sed 's|<.*>||g' | tr '\n' ' ' | tr -s ' ' | sed 's/ \././g')
		if [[ $(wc -c <<< "$extract") -gt 2096 ]]; then
			extract="$(head -c 2093 <<< "$extract")..."
		fi
		message_text=$(printf '%s\n\n' "$wiki_link" "$extract")
		description=$extract
		return_query=$(inline_array article)
		tg_method send_inline > /dev/null
	;;
	*" bin")
		if [[ $(is_admin) ]]; then
			command=$(sed 's/ bin$//' <<< "$inline_message")
			markdown=("<code>" "</code>")
			parse_mode=html
			message_text=$(mksh -c "$command" 2>&1)
			title="> $command"
			return_query=$(inline_array article)
			tg_method send_inline
		fi
	;;
	*)
		owoarray=("owo" "ewe" "uwu" ":3" "x3" "🥵" "🙈" "🤣" "😘" "🥺" "💁‍♀️" "OwO" "😳" "🤠" "🤪" "😜" "🤬" "🤧" "🦹‍♂" "🍌" "😏" "😒" "😎" "🙄" "🧐" "😈" "👐🏻" "👏🏻" "👀" "👅" "🍆" "🤢" "🤮" "🤡" "💯" "👌" "😂" "🅱️" "💦")
		numberspace=$(tr -dc ' ' <<< "$inline_message" | wc -c)
		if [[ "$numberspace" = "" ]]; then
			return
		fi
		for x in $(seq $(((numberspace / 8)+1))); do
			inline_message=$(sed "s/\s/\n/$(((RANDOM % numberspace)+1))" <<< "$inline_message")
		done
		for x in $(seq $(($(wc -l <<< "$inline_message") - 1))); do
			fixed_part[$x]=$(sed -n "${x}"p <<< "$inline_message" | sed "s/$/ ${owoarray[$((RANDOM % ${#owoarray[@]}))]} /")
		done
		fixed_text=$(printf '%s' "${fixed_part[*]}" "$(tail -1 <<< "$inline_message")" | tr -s ' ')
		
		title=$(sed -e 's/[lr]/w/g' -e 's/[LR]/W/g' <<< "$fixed_text")
		message_text=$title
		return_query=$(inline_array article)
		tg_method send_inline > /dev/null
	;;
esac
