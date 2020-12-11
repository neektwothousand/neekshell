booru_prefix=$(grep -o '^.*b\s\|^.*gif\s' <<< "$results" | sed 's/\s$//')

case "$booru_prefix" in
	'gb'|'gbgif')
		booru="gelbooru.com"
		ilb="g"
	;;
	'e621b'|'e621bgif')
		booru="e621.net"
		ilb="e621"
	;;
	'sb'|'sbgif')
		booru="safebooru.donmai.us"
		ilb="s"
	;;
esac

case $results in
	"fortune")
		fortune=$(/usr/bin/fortune fortunes paradoxum goedel linuxcookie | tr '\n' ' ' | awk '{$2=$2};1')
		title="Cookie"
		message_text=$(printf '%s\n' "Your fortune cookie states:" "$(/usr/bin/fortune fortunes paradoxum goedel linuxcookie | tr '\n' ' ' | awk '{$2=$2};1')")
		description="Open your fortune cookie"
		return_query=$(inline_array article)
		tg_method send_inline > /dev/null
	;;
	d[0-9]*)
		title="Result of $results"
		number=$(( ( RANDOM % $(sed 's/d//' <<< "$results") )  + 1 ))
		message_text=$(printf '%s\n' "$title" "$number")
		return_query=$(inline_array article)
		tg_method send_inline > /dev/null
	;;
	"figlet "*)
		figtext=$(sed 's/figlet //' <<< "$results")
		markdown=("<code>" "</code>")
		message_text=$(figlet -- "$figtext")
		title="figlet $figtext"
		return_query=$(inline_array article)
		tg_method send_inline > /dev/null
	;;
	"jafw "*)
		j_normal=$(sed -e "s/jafw //" -e "s/ /  /g" <<< "$results")
		j_fullw_low=$(sed -e 's/a/ａ/g' -e 's/b/ｂ/g' -e 's/c/ｃ/g' -e 's/d/ｄ/g' -e 's/e/ｅ/g' -e 's/f/ｆ/g' -e 's/g/ｇ/g' -e 's/h/ｈ/g' -e 's/i/ｉ/g' -e 's/j/ｊ/g' -e 's/k/ｋ/g' -e 's/l/ｌ/g' -e 's/m/ｍ/g' -e 's/n/ｎ/g' -e 's/o/ｏ/g' -e 's/p/ｐ/g' -e 's/q/ｑ/g' -e 's/r/ｒ/g' -e 's/s/ｓ/g' -e 's/t/ｔ/g' -e 's/u/ｕ/g' -e 's/v/ｖ/g' -e 's/w/ｗ/g' -e 's/x/ｘ/g' -e 's/y/ｙ/g' -e 's/z/ｚ/g' <<< "$j_normal")
		j_fullw=$(sed -e 's/A/Ａ/g' -e 's/B/Ｂ/g' -e 's/C/Ｃ/g' -e 's/D/Ｄ/g' -e 's/E/Ｅ/g' -e 's/F/Ｆ/g' -e 's/G/Ｇ/g' -e 's/H/Ｈ/g' -e 's/I/Ｉ/g' -e 's/J/Ｊ/g' -e 's/K/Ｋ/g' -e 's/L/Ｌ/g' -e 's/M/Ｍ/g' -e 's/N/Ｎ/g' -e 's/O/Ｏ/g' -e 's/P/Ｐ/g' -e 's/Q/Ｑ/g' -e 's/R/Ｒ/g' -e 's/S/Ｓ/g' -e 's/T/Ｔ/g' -e 's/U/Ｕ/g' -e 's/V/Ｖ/g' -e 's/W/Ｗ/g' -e 's/X/Ｘ/g' -e 's/Y/Ｙ/g' -e 's/Z/Ｚ/g' <<< "$j_fullw_low")
		j_trans=$(trans :ja -j -b "$j_normal")
		title="『 $j_trans — $j_fullw 』"
		message_text=$title
		return_query=$(inline_array article)
		tg_method send_inline > /dev/null
	;;
	"${ilb}b "*|"${ilb}booru "*)
		offset=$(($(jshon_n -e offset -u <<< "$inline")+1))
		tags=$(sed "s/${ilb}b \|${ilb}booru //" <<< "$results")
		limit=5 y=0
		case "$ilb" in 
			"e621")
				apikey=$(cat e621_api_key)
				getbooru=$(curl -A 'neekmkshbot/1.0 (by neek)' -s "https://e621.net/posts.json?tags=$tags&page=$offset&limit=$limit&$apikey")
				for j in $(seq 0 $((limit - 1))); do
					photo_url[$j]=$(jshon_n -e posts -e $y -e file -e url -u <<< "$getbooru")
					while [ "$(grep 'jpg\|png' <<< "${photo_url[$j]}")" = "" ]; do
						y=$((y+1))
						photo_url[$j]=$(jshon_n -e posts -e $y -e file -e url -u <<< "$getbooru")
					done
					thumb_url[$j]=${photo_url[$j]}
					caption[$j]="tag: $tags\\nsource: ${photo_url[$j]}"
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
					photo_url[$j]=$(jshon_n -e $y -e file_url -u <<< "$getbooru")
					while [ "$(grep 'jpg\|png' <<< "${photo_url[$j]}")" = "" ]; do
						y=$((y+1))
						photo_url[$j]=$(jshon_n -e $y -e file_url -u <<< "$getbooru")
						if [ "$y" -gt "10" ]; then
							break
						fi
					done
					thumb_url[$j]=${photo_url[$j]}
					caption[$j]="tag: $tags\\nsource: ${photo_url[$j]}"
					y=$((y+1))
				done
			;;
		esac
		return_query=$(inline_array photo)
		tg_method send_inline > /dev/null
	;;
	"search "*)
		offset=$(($(jshon_n -e offset -u <<< "$inline")+1))
		search=$(sed 's/search //' <<< "$results" | sed 's/\s/%20/g')
		searx_results=$(curl -s "https://archneek.zapto.org/searx/?q=$search&pageno=$offset&categories=general&format=json")
		for j in $(seq 0 $(($(jshon_n -e results -l <<< "$searx_results")-1)) ); do
			title[$j]=$(jshon_n -e results -e "$j" -e title -u <<< "$searx_results" | sed 's/"/\\"/g')
			url[$j]=$(jshon_n -e results -e "$j" -e url -u <<< "$searx_results" | sed 's/"/\\"/g')
			message_text[$j]="${title[$j]}\\n${url[$j]}"
			description[$j]=$(jshon_n -e results -e "$j" -e content -u <<< "$searx_results" | sed 's/"/\\"/g')
		done
		return_query=$(inline_array article)
		tg_method send_inline > /dev/null
	;;
	*" bin")
		if [ $(is_admin) ]; then
			command=$(sed 's/ bin$//' <<< "$results")
			markdown=("<code>" "</code>")
			message_text=$(mksh -c "$command" 2>&1)
			title="$~> $command"
			return_query=$(inline_array article)
			tg_method send_inline > /dev/null
		fi
	;;
esac
