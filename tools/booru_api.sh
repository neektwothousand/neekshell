#!/bin/mksh
booru_api() {
	if [[ "$n_posts" ]]; then
		case "$booru_site" in
			e621)
				if [[ "$(jshon -Q -e posts <<< "$getbooru")" ]]; then
					level="-e posts -e $x"
				else
					level="-e post"
				fi
			;;
			gelbooru)
				if [[ "$(jshon -Q -e post -e 0 <<< "$getbooru")" ]]; then
					level="-e post -e $x"
				else
					level="-e post"
				fi
			;;
			rule34|realbooru)
				level="-e $x"
			;;
		esac
	else
		case "$booru_site" in
			e621)
				if [[ "$(jshon -Q -e posts <<< "$getbooru")" ]]; then
					n_posts=$(jshon -Q -e posts -l <<< "$getbooru")
				else
					n_posts=1
				fi
			;;
			gelbooru)
				if [[ "$(jshon -Q -e post -e 0 <<< "$getbooru")" ]]; then
					n_posts=$(jshon -Q -e post -l <<< "$getbooru")
				else
					n_posts=1
				fi
			;;
			rule34|realbooru)
				if [[ "$(jshon -Q -e 0 <<< "$getbooru")" ]]; then
					n_posts=$(jshon -Q -l <<< "$getbooru")
				else
					n_posts=1
				fi
			;;
		esac
	fi
	case "$1" in
		width)
			case "$booru_site" in
				gelbooru)
					jshon -Q $level -e width -u <<< "$getbooru"
				;;
			esac
		;;
		height)
			case "$booru_site" in
				gelbooru)
					jshon -Q $level -e height -u <<< "$getbooru"
				;;
			esac
		;;
		tags)
			case "$booru_site" in
				e621)
					jshon -Q $level -e tags -e general <<< "$getbooru" | head -n -1 | sed -e 1d -e 's/ "//' -e 's/"//g' -e 's/,//g'
				;;
				rule34|gelbooru|realbooru)
					jshon -Q $level -e tags -u <<< "$getbooru" | tr ' ' '\n'
				;;
			esac
		;;
		id)
			case "$booru_site" in
				rule34|gelbooru|e621|realbooru)
					jshon -Q $level -e id -u <<< "$getbooru"
				;;
			esac
		;;
		file)
			case "$booru_site" in
				e621)
					jshon -Q $level -e file -e url -u <<< "$getbooru"
				;;
				rule34|gelbooru)
					printf '%s' "$(jshon -Q $level -e file_url -u <<< "$getbooru" | sed -E 's/(.*\/).*/\1/')" \
						"$(jshon -Q $level -e image -u <<< "$getbooru")"
				;;
				realbooru)
					printf '%s' "https://$website//images/" \
						"$(jshon -Q $level -e directory -u <<< "$getbooru")/" \
						"$(jshon -Q $level -e image -u <<< "$getbooru")"
				;;
			esac
		;;
		sample)
			case "$booru_site" in
				e621)
					jshon -Q $level -e sample -e url -u <<< "$getbooru"
				;;
				rule34)
					jshon -Q $level -e sample_url -u <<< "$getbooru"
				;;
				gelbooru)
					hash=$(jshon -Q $level -e hash -u <<< "$getbooru")
					booru_dir=$(jshon -Q $level -e directory -u <<< "$getbooru")
					printf '%s\n' "https://$website/samples/$booru_dir/sample_$hash.jpg"
				;;
			esac
		;;
		has_sample)
			case "$booru_site" in
				e621)
					if [[ "$(jshon -Q $level -e sample -e has -u <<< "$gebooru")" == "true" ]]; then
						printf '%s\n' "true"
					fi
				;;
				rule34|gelbooru|realbooru)
					if [[ "$(jshon -Q $level -e sample -u <<< "$getbooru")" != "0" ]]; then
						printf '%s\n' "true"
					fi
				;;
			esac
		;;
		hash)
			case "$booru_site" in
				e621)
					jshon -Q $level -e file -e md5 -u <<< "$getbooru"
				;;
				rule34|gelbooru|realbooru)
					jshon -Q $level -e hash -u <<< "$getbooru"
				;;
			esac
		;;
		rating)
			case "$booru_site" in
				rule34|gelbooru|e621|realbooru)
					jshon -Q $level -e rating -u <<< "$getbooru"
				;;
			esac
		;;
	esac
}
