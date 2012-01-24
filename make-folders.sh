#!/bin/bash

if [ "$1" == "--full" ]; then
   full=1
else
   full=0
fi

extract () {
	cat "$1" | pextract "^$2:\s*(.*)" | tail -1
}

find messages -maxdepth 1 -type d | pcregrep ":\d\d$" | while read folder; do

	index="$folder/index.html"
	foldername=`basename "$folder" | ./encode-html.pl`

	if [ $full -eq 0 ] && [ -f "$index" ]; then
		echo directory already processed : $folder
		continue
	else
		echo processing directory : $folder
	fi

	(
		cat <<__DATA__

<html><head>
<title>$foldername</title>
<style>
div {
	border: 1px solid gray;
	padding: 10px;
}
</style></head>
<body>
<div>

__DATA__

	) > "$index"

	echo "<table border=0><tr><th>No.</th><th>From</th><th>Subject</th><th>Date</th></tr>" >> "$index"

	find "$folder" -type d | pcregrep "/\d\d\d\d$" | while read message; do

		echo "- processing message $message"

		rfc="$message/rfc822.txt"

		name=`basename "$message"`
		from=`extract "$rfc" From | ./encode-html.pl`
		date=`extract "$rfc" Date | ./encode-html.pl`
		subject=`extract "$rfc" Subject | ./encode-html.pl`

		echo "<tr><td><a href="$name">$name</a></td><td>$from</td><td><i>&quot;$subject&quot;</i></td><td>$date</td></tr>" >> "$index"

	done

	echo "</table></div>" >> "$index"

	echo "</body></html>" >> "$index"

done
 
