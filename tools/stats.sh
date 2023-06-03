#!/bin/mksh
if [[ "$chat_id" != "" ]] || [[ "$user_id" != "" ]]; then
	twd
	data_id=$RANDOM
	num_arg=$(grep -o "[0-9]*" <<< "${arg[0]}")
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
	elif [[ ! "$num_arg" ]]; then
		sed -n "s/.$chat_id./ /p" "$basedir/stats/chats-usage" | tail -n 7 | sed -e 's/^..//' -e 's/^../&\//' -e 's/^...../"&"/' > "$data_id-data"
		gnuplot -persist <<EOF
			set terminal pngcairo enhanced font "Ubuntu,14" fontscale 1.0 size 1280, 720
			set output "$data_id-out.png"
			set boxwidth 0.4 relative
			set style fill pattern 7
			set style line 1 lt 1 lc rgb '#284165'
			set yrange [ 0 : * ]
			set title "messages sent every day" font "Ubuntu,18"
			set border 3
			set tics nomirror

			plot "$data_id-data" using 2:xticlabels(1) with boxes notitle ls 1, '' using 0:2:2 with labels notitle
EOF
		photo_id="@$data_id-out.png"
	else
		data=$(sed -n "s/.$chat_id./ /p" "$basedir/stats/chats-usage" | tail -n "$(($num_arg+1))" | head -n -1 | sed 's/^....../""/')
		printf '%s\n' "$data" | head -n 1 > "$data_id-data"
		printf '%s\n' "$data" >> "$data_id-data"
		printf '%s\n' "$data" | tail -n 1 >> "$data_id-data"
		gnuplot <<EOF
			set terminal pngcairo enhanced font "Ubuntu,14" fontscale 1.0 size 1000, 400
			set output "$data_id-out.png"
			set boxwidth 0.6 relative
			set style fill pattern 7
			set style line 1 lt 1 lc rgb '#284165' lw 2
			set style line 2 lt 1 lc rgb '#7b284165' lw 26
			set yrange [ 0 : * ]
			set xrange [ 1 : * ]
			set title "messages sent every day" font "Ubuntu,18"
			set border 3
			set tics nomirror
			plot "$data_id-data" using 2:xticlabels(1) with fillsteps fillcolor rgb "#284165" notitle, \
			"" using 2:xticlabels(1) with steps ls 1 notitle, \
			"" using 2:xticlabels(1) smooth bezier with fillsteps fillstyle transparent solid 0.5 fillcolor rgb "#284165" notitle
EOF
		photo_id="@$data_id-out.png"
	fi
fi
