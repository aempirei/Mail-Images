#!/bin/bash

if [ "$1" == "--full" ]; then
	full=1
else
	full=0
fi

exts="jpg.djpeg gif.giftopnm png.pngtopnm bmp.bmptopng tif.tifftopnm"

extract () {
	cat "$1/rfc822.txt" | pextract "^$2:\s*(.*)" | tail -1
}

find messages/ -type d | pcregrep '/\d\d\d\d$' | while read dir; do

	excludes="/(index.html|subject.txt|rfc822.txt)$"

	index="$dir/index.html"
	subject_fn="$dir/subject.txt"

	if [ $full -eq 0 ] && [ -f "$index" ]; then
		echo directory already processed : $dir
		continue
	else
		echo processing directory : $dir
	fi

	#
	# start the index file by displaying the header
	#

	subject=`cat "$subject_fn" | ./encode-html.pl`

	from=`extract "$dir" "From" | ./encode-html.pl`
	date=`extract "$dir" "Date" | ./encode-html.pl`

	(

		cat <<__DATA__
<html><head>
<title>$subject</title>
</head>
<style>
div {
	border: 1px solid gray;
	display: block;
	padding: 10px;
	margin-bottom: 10px;
}
</style>
<body>

<div id='header'>
<p>
	<b>From:</b> $from<br>
	<b>Date:</b> $date<br>
	<b>Subject:</b> $subject<br>

	<br>

	[<a href="rfc822.txt">raw message</a>]

</p>
</div>

__DATA__

		#
		# list and link each mime part
		#

		echo "<div id='parts'>"

		find "$dir" -maxdepth 1 -type f | pcregrep -v "$excludes" | while read fn; do
			base=`basename "$fn"`
			echo "<a href='$base'>$base</a><br>"
		done

		echo "</div>"

	) > "$index"

	thumbdir="$dir/thumbs"

	mkdir -vp "$thumbdir"

	echo "<div id='thumbs'>" >> "$index"

	for pair in $exts; do

		read ext app <<<"${pair/./ }"
		echo handling "*.$ext" via `which $app`

		find "$dir" -maxdepth 1 -type f -name "*.$ext" | while read fn; do

			base=`basename "$fn" ".$ext"`

			thumb="$thumbdir/th.$base.jpg"

			$app "$fn" | pnmscale -ysize 200 | cjpeg -verbose -optimize -quality 95 > "$thumb"

			echo "<a href='$base.$ext'><img src='thumbs/th.$base.jpg'></a>" >> "$index"

		done
	done

	echo "</div>" >> "$index"

	#
	# expand each text/html part
	#

	find "$dir" -maxdepth 1 -type f -name "*.txt" | pcregrep -v "$excludes" | while read fn; do
		echo "<div>"
		cat "$fn"
		echo "</div>"
	done >> "$index"

	find "$dir" -maxdepth 1 -type f -name "*.html" |  pcregrep -v "$excludes" | while read fn; do
		echo "<div>"
		cat "$fn"
		echo "</div>"
	done >> "$index"

	echo "</body></html>" >> "$index"

	name=`basename "$dir"`

done
