#!/usr/bin/env bash

if [ "$USER" == "" ]; then
	USER=`whoami`
	PATH=$PATH:/home/$USER/bin
fi

./fetch-mail.sh &

child=$!

(
	sleep 30

	if [ -d /proc/$child ]; then
		kill -9 $child
	fi

	rm -f ./lockfile
) &

sleeper=$!

wait $child

if [ $? -ne 0 ]; then
	exit
fi

if [ -d /proc/$sleeper ]; then
	kill -9 $sleeper
fi

mboxdir='./aempirei.rfc822-emails.d'
postdir='./messages/'`date '+%Y-%m-%d_%H:%M:%S'`

if [ ! -d "$mboxdir" ]; then
	echo mbox directory "$mboxdir" does not exist
	exit
fi

msg_count=`find "$mboxdir" -type f | wc -l`

if [ $msg_count -eq 0 ]; then
	echo no messages
else
	mkdir -pv "$postdir"

	find "$mboxdir" -type f | while read full_fn; do
		fn=`basename "$full_fn"`
		boxify <<<"processing $full_fn"
		./mime-explode.pl "$postdir/$fn" < "$full_fn"
		cp -v "$full_fn" "$postdir/$fn/rfc822.txt"
	done
fi

rm -rv "$mboxdir"

boxify <<<"Removing CRON messages."

find messages -type f -name rfc822.txt |  while read fn; do
	dir=`dirname "$fn"`
	cat "$fn" | grep -q '^From root@modron' && rm -rv "$dir"
done

find messages -type d -exec rmdir -vp {} \;

boxify <<<"Making message previews."
./make-previews.sh
boxify <<<"Making message folders."
./make-folders.sh

boxify <<<"Cleaning up junk folders."

find messages -type d -exec rmdir -vp {} \;


