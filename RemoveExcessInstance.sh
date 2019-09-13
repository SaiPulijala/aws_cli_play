#!/bin/bash

for cluster in ccplay-sandbox-standard ccplay-sandbox-large ccplay-sandbox-mlarge
do
	if [[ $cluster == "ccplay-sandbox-standard" ]]; then ASG=ccplay-sandbox-standard-autoscalling-group; fi
	if [[ $cluster == "ccplay-sandbox-large" ]]; then ASG=ccplay-sandbox-large-autoscalling-group; fi
	if [[ $cluster == "ccplay-sandbox-mlarge" ]]; then ASG=ccplay-sandbox-mlarge-autoscalling-group; fi

	echo $cluster
	echo $ASG

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
		
			echo $i 
			echo $InstanceID
			echo $i,$InstanceID >> containerinstancestoremove.txt
			count=$((count+1))
			echo $count
		fi
	done < containerinstances.txt



	while IFS=, read -r a b 
	do
	
 
		echo $count
			
		if [[ $count != 0 ]] && [[ $count != 1 ]]
		then 
		
		echo $a
		
		echo $b
		
		aws ecs update-container-instances-state --cluster $cluster --container-instances $a --status DRAINING
		
		aws autoscaling detach-instances --instance-ids $b --auto-scaling-group-name $ASG --should-decrement-desired-capacity
		
		aws ec2 terminate-instances --instance-ids $b
		
		fi
		
		count=$((count-1))
		
		echo $count
		
	
	done < containerinstancestoremove.txt
	
	

	rm -f containerinstancestoremove.txt
	
	
done
