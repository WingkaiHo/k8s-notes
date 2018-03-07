#!/bin/bash

echo "Start to delete elasticsearch data."

dtime=`date -d "{{ ELA_STORAGE_LIFT | default("7") }} day ago" +%Y-%m-%d`
dtime_stamp=`date -d "$dtime" +%s`

indexs=`curl -s 'http://elasticsearch-logging:9200/_cat/indices' | awk '$3~/^logstash/{print $3}'`

if [ $? -ne 0 ]; then
	echo "Fail to connect elasticsearch service."
	exit 1
fi

echo "indexs: $indexs"

for line in $indexs;do
  echo "$line"
  index=$line
  itime=`echo $line | awk -F - '{print $2}' | tr '.' '-'`
  itime_stamp=`date -d "$itime" +%s`

  if [ $itime_stamp -le $dtime_stamp ];then
	curl -X DELETE "http://elasticsearch-logging:9200/$index" > /dev/null 2>&1
	if [ $? -ne 0 ]; then
		echo "Fail to delete index:$index"
		exit 1
	fi
	echo "Delete index:$index"
  fi
done
