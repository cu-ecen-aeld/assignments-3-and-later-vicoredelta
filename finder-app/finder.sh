#!/bin/sh

filesdir=$1
searchstr=$2

if [ "$#" -ne 2 ]
then
	echo "Script takes two arguments"
	exit 1
fi

if [ ! -d "$filesdir" ]
then
	echo "$filesdir is not a directory"
	exit 1
fi

files=$(find "$filesdir" -type f)
X=$(find "$filesdir" -type f | wc -l)
Y=$(cat $files | grep -c "$searchstr")

echo "The number of files are $X and the number of matching lines are $Y"
