#!/bin/bash

aws ecs list-container-instances --cluster $1 > InstanceIDS.json

jq -r '.containerInstanceArns[]' InstanceIDS.json > InstanceIDS.txt


sed -i -r 's/.*\///' InstanceIDS.txt


while read i
do
        echo "updating ECS agent on container instance $i"
        aws ecs update-container-agent --cluster $1 --container-instance $i
	sleep 1
done < InstanceIDS.txt


