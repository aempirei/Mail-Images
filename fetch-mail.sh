#!/usr/bin/env bash

if [ "$USER" == "" ]; then
	USER=`whoami`
	PATH=$PATH:/home/$USER/bin
fi

mbox="/var/mail/$USER"
tmpfile="/tmp/$USER-mbox-backup"
mboxdir="./$USER.rfc822-emails.d"
lockfile="./lockfile"
rc="./fetchmailrc"

function save_mbox {
	boxify <<<$FUNCNAME
	cp -v "$mbox"  "$tmpfile"
	cp -v /dev/null "$mbox"
}

function restore_mbox {
	boxify <<<$FUNCNAME
	cp -v "$tmpfile" "$mbox"
	rm -v "$tmpfile"
}

function fetch_mbox {
	boxify <<<$FUNCNAME
	fetchmail -v -f "${rc}"
}

function split_mbox {
	boxify <<<$FUNCNAME
	splitmbox.pl -n=4 "$mbox" "$mboxdir"
}

function cleanup {
	boxify <<<$FUNCNAME
	rm -vf "$lockfile"
}

function mbox_count {
	e=^`basename "$mboxdir"`
	let count=`ls | pcregrep "$e" | wc -l`
	echo "THE PATTERN IS /$e/"
	ls | pcregrep "$e" | wc -l
	return $count
}

function initialize {
	boxify <<<$FUNCNAME
	if [ -d "$mboxdir" ]; then
		echo WE ALREADY SEE A DIRECTORY
		mbox_count
		let n=$?
		mv -v "$mboxdir" "$mboxdir.$n"
	fi

	lockfile "$lockfile"
	trap cleanup SIGALRM
}

initialize

save_mbox

fetch_mbox

split_mbox

restore_mbox

cleanup
