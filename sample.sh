#!/bin/bash
count=3
while IFS=, read -r a b

do
	if [[ $count != 0 ]] && [[ $count != 1 ]]
	then 
	echo $a
	echo $b
	echo $count
	sleep 3
	fi 
	count=$((count-1))
done < ../aws_cli_play/containerinstancestoremove.txt
rm -fr ../aws_cli_play/containerinstancestoremove.txt