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
		api_key=$(cat gelbooru_key)
		no_video="-video+-webm+-animated+-animated_gif+-animated_png"
		getbooru=$(curl -A 'Mozilla/5.0' -s "https://$website/index.php?page=dapi&s=post&json=1&pid=$offset&tags=$tags+$no_video&q=index&limit=$limit$api_key")
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
		pref="eJx9V02P3DYM_TWdi7GLpjn0NIeiRZEABRJ0N70atER7GEuio4-Z9f76UjP-kHa2PWQCyaLERz4-chVEHNgThuOADj2YgwE3JBjwiO7h29PBsAKTFwdIkRXbyWDE43XVs0rh-OwTHsCrE52xjaxhPv4JJuCBrFzTTp5f1h2L8cT6-PXL0_MhQI8Bs93x50M8ocUjBwX-4DEkE0PLrnV4aSN0i7VmauUjmzP6I4MsH9kPh6vVQ4izuGl4IMUazw8a_HgAfQanULfLQ8s9FKAzsotuICfQu6hpGNrWpkDqp19-v60CKwLTWNQEsnmhkQInr7Btl1jJ7o8LuNhckYa2vf0v2wPzYLAJ6sQGvNylCMUR-TLDibm8oSM3NAJUzPNvPjIMkb1HF9u2J3O9kNyZNHEKu5fJd-A0qUjswM_VnQug1RpezexJhfKMTmrM_wa-d18p9RDPbStvIl-ft7orjacTR8lPa2HKaGmQgEKI5ZGR1Agh7E74ZCXqxaVnssjFeiIvdOxg3jG6GaA4YbgLER999jXmnLDpPVgw0wnKIOdcVSENaUKfAvrFUOuh0diToxy9Ki4W3EjbQZ-6eUC7PUhdFegLv9DI7lFLrmfHbrYVO2ZOMXUlZp7QCX0DFtG-MuAuBxrIzJazf4X9La8LqnwZkMcpdYYULFD2MEzzRIvjAQVXJPUeJQ11XgjUZL8D1cHI5JfiHM-Elwt2pSc8TGQquL0niR2oAgWEMXXJxbT4sRD7dU_xUipVuiR_77B6t915uZfFtjdQNNAt7006h78ovzUjNcNWjuZyemVXoSJXUvAEEqz8szxgJHlnqJJelO9mdjmJigYjy_Logn0yMDeWJcYlDo9aU9xikgWskdfSS5PpvTy_6G5Tp22YWOvM4RXXtvFG1AK-OrBVkKVw5pKd8ilmxbqFM3ViWgb0w8ePv74UXmMU0jrxswI6Quqlseh76bwZlrzadKlthXF7lO5FFlFoYnEtzk1x1tyGCGpkKbfe8GUtBE5OK8NJ7-eEpJW47Tq0xk95DsFjXyKHaWwsec9FnJMLksxwelvddyh77Zn0bnij4eqQSpk_qmK_5e-Ct1Zwja7cuF2yvbzWNfeNYjdI6yyjB_6FziWe8H16nC7VhZYycO5jAwo0yrKSF0T_Rt56j6KEYnABj40WbVJSC_OqungmyTn4WMbHw7niysr7d_rvmec8UpQCnHdFTylWwXKTXd5EIa8J_5Heze_I4ywdLZx4BLfnITdYBXa6U6u7fF7bei1iE0Yw7wF7Xyq2F9BR2eYzQiuNqrS7eS_eTpOw61rHWQjy5NPknwW7CNntQ2Xr-UL6XbXYt-5awsrT0xX_1lQmgvWFqsWFKESIMh2sI4KVzmiFCU304IKRBOha2qv4r6_10tZGX5DFCVcqR-PZwmvFiA8vxXkZFkkvIS5QXNhrR-P_eLCh2URl7y-FaMM0Fddm5NKNudjK2ejQD9v8MNKPxPGOwx3zWHdeenmjUnv7Wy9fx7yy9Z3S2vo6ip3oKMZ1lFnotwXnNjpJptd83hS5IvE6YmiIkulYjRca8TVn4-rgQc5VQ3Wp429Ev9wIWQ6msqr3-XwySe4Kx09ZUW8LsXi6EU7GInX762WW8d6I0Fy_mb797Hr29jYOyd4_ZB8MjdjKzDriHIorZCgECWve-sQhSitE-QtDMnvF9-ylfQjAb3__Jbs2NxLZldvz2IgSCM8mQ_giMWp_Uyrr6x9fPsvZi5cD-dLn569P63qL0ArrIJyTUjn-C00MGhs="
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
			button_url="https://t.me/neekshellbot?start=join$join_id"
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
