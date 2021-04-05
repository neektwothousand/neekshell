#!/bin/mksh
if [[ "$chat_id" != "" ]] || [[ "$user_id" != "" ]]; then
	if [[ "$s_target" == "users" ]]; then
		if [[ "$s_time" == "today" ]]; then
			usage=$(grep -w -- "$(date +%y%m%d):$user_id" stats/users-usage | cut -f 3 -d :)
			if [[ "$usage" != "" ]]; then
				text_id="Today usage in ms: $usage"
			fi
		else
			usage=$(grep -w -- "$(date +%y%m%d -d "yesterday"):$user_id" stats/users-usage | cut -f 3 -d :)
			if [[ "$usage" != "" ]]; then
				text_id="Yesterday usage in ms: $usage"
			fi
		fi
	else
		cd "$tmpdir"
		data_id=$RANDOM
		sed -n "s/.$chat_id./ /p" "$basedir/stats/chats-usage" | tail -n 7 | sed -e 's/^..//' -e 's/^../&\//' -e 's/^...../"&"/' > "$data_id-data"
		gnuplot -persist <<EOF
			set terminal png enhanced font "Ubuntu,14" fontscale 1.0 size 1280, 720
			set output "$data_id-out.png"
			set boxwidth 0.4 relative
			set style fill solid 0.6
			set yrange [ 0 : * ]
			set title "messages sent every day" font "Ubuntu,18"
			plot "$data_id-data" using 2:xticlabels(1) with boxes notitle, '' using 0:2:2 with labels notitle
EOF
		photo_id="@$data_id-out.png"
		rm -f "$data_id-data"
	fi
fi
