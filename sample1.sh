#!/bin/bash

for cluster in ccplay-sandbox-standard ccplay-sandbox-large ccplay-sandbox-mlarge
do
	if [[ $cluster == "ccplay-sandbox-standard" ]]; then ASG=ccplay-sandbox-standard-autoscalling-group; fi
	if [[ $cluster == "ccplay-sandbox-large" ]]; then ASG=ccplay-sandbox-large-autoscalling-group; fi
	if [[ $cluster == "ccplay-sandbox-mlarge" ]]; then ASG=ccplay-sandbox-mlarge-autoscalling-group; fi

	echo $cluster
	sleep 10
	echo $ASG
	sleep 10
	echo initial $cluster $ASG
done
