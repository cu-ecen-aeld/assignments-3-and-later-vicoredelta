#!/bin/sh

set -e
set -u

if [ $# -lt 2 ]
then
    echo "Error, script takes two arguments."
    exit 1
fi

FILESDIR=$1
SEARCHSTR=$2


if [ ! -d $1 ]
then
    echo "Error, ${FILESDIR} invalid filename."
    exit 1
fi

FILENUM=`grep -ril ${SEARCHSTR} ${FILESDIR} | wc -l`
MATCHNUM=`grep -ri ${SEARCHSTR} ${FILESDIR} | wc -l`

echo "The number of files are ${FILENUM} and the number of matching lines are ${MATCHNUM}"
