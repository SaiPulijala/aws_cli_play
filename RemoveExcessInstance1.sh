#!/bin/bash

cluster='cc-production-mxlarge'

ASG='cc-production-mxlarge-asg'

aws ecs list-container-instances --cluster $cluster > containerinstances.json

jq -r '.containerInstanceArns[]' containerinstances.json > containerinstances.txt

sed -i -r 's/.*\///' containerinstances.txt

count=0

while read -r i
do
	aws ecs describe-container-instances --cluster $cluster --container-instances $i > containerinfo.json
	if [[ $(jq -r '.containerInstances[].runningTasksCount' containerinfo.json) == 0 ]]
	then
	
		InstanceID=$(jq -r '.containerInstances[].ec2InstanceId' containerinfo.json)
		
		echo 'ContainerID='$i 
		
		echo 'InstanceID='$InstanceID
		
		echo $i,$InstanceID >> containerinstancestoremove.txt
		
		count=$((count+1))
		
		echo 'Number of Container and EC2 instance with zero running tasks='$count
	fi
done < containerinstances.txt



if [[ $count == 0 ]] || [[ $count == 1 ]]
then
	echo 'Number of Container and EC2 instances with zero running tasks='$count
	echo 'so exiting now'
	rm -fr containerinstancestoremove.txt
	exit
else
	echo 'Number of Container and EC2 instances with zero running tasks='$count
	count=$((count-1))
	echo 'container instances with 0 running to be removed='$count
	sed -i '$d' containerinstancestoremove.txt
fi

a=''
b=''

while IFS=, read -r Cid EC2id

do

	a=$a,$Cid
	b=$b,$EC2id
	
done < containerinstancestoremove.txt

echo $a
echo $b



echo 'draining container Instance IDs='$a
		
aws ecs update-container-instances-state --cluster $cluster --container-instances {'$a'} --status DRAINING
		
echo 'detaching instance IDs='$b
		
aws autoscaling detach-instances --instance-ids {'$b'} --auto-scaling-group-name $ASG --should-decrement-desired-capacity
		
echo 'terminating instance IDs='$b
		
aws ec2 terminate-instances --instance-ids {'$b'}
		
rm -fr containerinstancestoremove.txt
