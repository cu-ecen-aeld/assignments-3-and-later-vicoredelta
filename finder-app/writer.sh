#!/bin/sh

writefile=$1
writestr=$2

if [ "$#" -ne 2 ]
then
        echo "Script takes two arguments"
        exit 1
fi

if [ ! -f $writefile ]; then
	mkdir -p $writefile
	rm -d $writefile
	touch $writefile $writestr
fi

echo "$writestr" > $writefile
