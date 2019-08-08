#!/bin/bash

aws ecs list-container-instances --cluster $1 > containerinstances.json

jq -r '.containerInstanceArns[]' containerinstances.json > containerinstances.txt

sed -i -r 's/.*\///' containerinstances.txt


count=0

while read -r i
do
	aws ecs describe-container-instances --cluster $1 --container-instances $i > containerinfo.json
	if [[ $(jq -r '.containerInstances[].runningTasksCount' containerinfo.json) == 0 ]]
	then
		InstanceID=$(jq -r '.containerInstances[].ec2InstanceId' containerinfo.json)
		
		echo $i 
		echo $InstanceID
		echo $i,$InstanceID >> containerinstancestoremove.txt
		count=$((count+1))
		echo $count
	fi
done < containerinstances.txt



if [[ $count == 0 ]] || [[ $count == 1 ]]
then
	echo $count
	rm -fr containerinstancestoremove.txt
	exit
else
	echo "container instances with 0 Running tasks are $count"
	count=$((count-1))
	echo "container instances with 0 running to be removed $count"
fi


while IFS=, read -r a b 
do
	
 	
		echo $a
		echo $b
		echo $count
		
		read -p "Draining $a, Detaching $b and terminating $b [y/n] :" value < /dev/tty
		
		if [[ $value == "y" ]]
		then
		
		aws ecs update-container-instances-state --cluster $1 --container-instances $a --status DRAINING
		
		aws autoscaling detach-instances --instance-ids $b --auto-scaling-group-name $2 --should-decrement-desired-capacity
		
		aws ec2 terminate-instances --instance-ids $b
		
		fi
		
		count=$((count-1))
		echo $count
		if [[ $count == 0 ]]
                then
				rm -fr containerinstancestoremove.txt
                        exit
                fi


	fi
done < containerinstancestoremove.txt


