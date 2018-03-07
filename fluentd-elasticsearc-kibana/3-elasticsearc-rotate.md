### 3.1 Elasticsearc 索引数据清理
如果不定是清理，日志索引索引数据越来越多，可以通过定时器对日志数据进行清理。

### 3.1.1 日志清理脚本
日志清理可以通过api对Elasticsearc过期日志数据进行清理，下面例子是把7天以前日志数据进行清理。

- 编辑del-esindex.sh

```
#!/bin/bash
echo "Start to delete elasticsearch data."
if [ ! -n "$ELA_STORAGE_LIFT" ]; then
	echo "Please set env ELA_STORAGE_LIFT"
	exit 1
fi

dtime=`date -d "$ELA_STORAGE_LIFT day ago" +%Y-%m-%d`
dtime_stamp=\`date -d "$dtime" +%s\`

indexs=\`curl -s \'http://elasticsearch-logging:9200/_cat/indices' | awk '$3~/^logstash/{print $3}'\`

if [ $? -ne 0 ]; then
	echo "Fail to connect elasticsearch service."
	exit 1
fi

for line in $indexs;do
  echo "$line"
  index=$line
  itime=\`echo $line | awk -F - '{print $2}' | tr '.' '-'`
  itime_stamp=\`date -d "$itime" +%s\`

  if [ $itime_stamp -le $dtime_stamp ];then
	curl -X DELETE "http://elasticsearch-logging:9200/$index" > /dev/null 2>&1
	if [ $? -ne 0 ]; then
		echo "Fail to delete index:$index"
		exit 1
	fi
	echo "Delete index:$index \n"
  fi
done
```

### 3.1.2 制作镜像
进入目录dockerfile-clean-elasticsearc-data执行制作镜像脚本， 推送harbor就可以

### 3.1.3 启动Elasticsearc数据
编辑cleanup-ela-data-deployment.yaml, 配置镜像，以及环境变量。
```
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: crontab-cleanup-ela-data
  namespace: "kube-system"
  labels:
    k8s-app: crontab-cleanup-ela-data
spec:
  replicas: 1
  selector:
    matchLabels:
      k8s-app: crontab-cleanup-ela-data
  template:
    metadata:
      labels:
        k8s-app: crontab-cleanup-ela-data
    spec:
      containers:
      - image: "192.168.0.1/library/crontab-cleanup-ela-data:1.0"
        name: crontab-cleanup-ela-data
        resources:
          # need more cpu upon initialization, therefore burstable class
          limits:
            cpu: 100m
            memory: 50Mi
          requests:
            cpu: 100m
            memory: 30Mi
        env:
        #通过此环境变量可以控制保存日志时间长度，当前保存日志时间7天
        - name: ELA_STORAGE_LIFT
          value: "7"
```

部署到kubernetes集群上
```
$kuberctl apply -f cleanup-ela-data-deployment.yaml
```