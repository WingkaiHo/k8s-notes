#! /bin/bash

CURRENT_PAHT=`pwd`
JSON_FILES=$(ls $CURRENT_PAHT/*.json)


#kubectl create configmap grafana-dashboards-0 --from-file=nodes-dashboard.json --dry-run -o yaml
FROM_FILE_STR=''
for filename in $JSON_FILES
do
	   FROM_FILE_STR=$FROM_FILE_STR' --from-file='$filename 
done

kubectl create configmap grafana-dashboards-0 $FROM_FILE_STR --dry-run -o yaml > grafana-dashboards.yaml
