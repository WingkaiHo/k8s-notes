## 基于 k8s Metrics-server HPA(弹性伸缩)
   从 v1.8 开始，资源使用情况的度量（如容器的 CPU 和内存使用）可以通过 Metrics API 获取。注意
   - Metrics API 只可以查询当前的度量数据，并不保存历史数据
   - Metrics API URI 为 /apis/metrics.k8s.io/
   - 必须部署 metrics-server 才能使用该 API，metrics-server 通过调用 Kubelet Summary API 获取数据

### 开启API Aggregation
在部署 metrics-server 之前，需要在 kube-apiserver 中开启 API Aggregation，即增加以下配置(kubespray 自动化安装可以省略此步骤)
```
--requestheader-client-ca-file=/etc/kubernetes/certs/proxy-ca.crt
--proxy-client-cert-file=/etc/kubernetes/certs/proxy.crt
--proxy-client-key-file=/etc/kubernetes/certs/proxy.key
--requestheader-allowed-names=aggregator
--requestheader-extra-headers-prefix=X-Remote-Extra-
--requestheader-group-headers=X-Remote-Group
--requestheader-username-headers=X-Remote-User
- --runtime-config=admissionregistration.k8s.io/v1alpha1,api/all=true

```
如果kube-proxy没有在Master上面运行，还需要配置
```
--enable-aggregator-routing=true
```

### 部署metrics server

通过 kubepray 部署注意修改inventory/you-sample/group_vars/all.yaml
```
# The read-only port for the Kubelet to serve on with no authentication/authorization. Uncomment to enable.
kube_read_only_port: 10255
```
否则node节点Kubelet 没有打开10255端口， metrics-server工作不正常

部署metrics
```
$ git clone https://github.com/kubernetes-incubator/metrics-server
$ cd metrics-server
$ kubectl create -f deploy/1.8+/
```
对应的镜像需要翻墙下载


### Metrics API

可以通过 kubectl proxy 来访问 Metrics API：
```
- http://master-ip:8080/apis/metrics.k8s.io/v1beta1/nodes
- http://master-ip:8080/apis/metrics.k8s.io/v1beta1/nodes/<node-name>
- http://master-ip:8080/apis/metrics.k8s.io/v1beta1/pods
- http://master:8080/apis/metrics.k8s.io/v1beta1/namespaces/<namespace-name>/pods/<pod-name>
```

也可以直接通过 kubectl 命令来访问这些 API，比如
```
- kubectl get --raw apis/metrics.k8s.io/v1beta1/nodes
- kubectl get --raw apis/metrics.k8s.io/v1beta1/pods
- kubectl get --raw apis/metrics.k8s.io/v1beta1/nodes/<node-name>
- kubectl get --raw apis/metrics.k8s.io/v1beta1/namespaces/<namespace-name>/pods/<pod-name>
```
也可以通过下面命令
```
$kubectl api-versions
```

### 排错
如果发现 metrics-server Pod 无法正常启动，比如处于 CrashLoopBackOff 状态，并且 restartCount 在不停增加，则很有可能是其跟 kube-apiserver 通信有问题。查看该 Pod 的日志，可以发现
```
dial tcp 10.233.0.1:443 i/o timeout
```
10.233.0.1 是kubernetes server-cluster-ip-range 第一个地址， 内部pod访问api-server , 此段地址由参数`--service-cluster-ip-range=10.233.0.0/18` 决定的

解决方法是：
```
echo "ExecStartPost=/sbin/iptables -P FORWARD ACCEPT" >> /etc/systemd/system/docker.service.d/exec_start.conf
systemctl daemon-reload
systemctl restart docker
```

## 通过metrics指标进行hpa测试
  默认情况下k8s hpa只能支持cpu使用率进行hpa，如果安装了metrics-server以后可以对pod cpu， 内存进行监控， 可以配置cpu， 内存使用率进行hpa


### 创建应用

创建php-apache应用， 要进行hpa必须配置资源限制，否则无法镜像扩展, 为了方便压力测试，把cpu限制100微核， 内存限制为100M

php-apache-deployment.yaml
```
apiVersion: apps/v1beta1
kind: Deployment
metadata:
  name: php-apache
  labels:
    dcos-app: php-apache
spec:
  replicas: 1 # tells deployment to run 2 pods matching the template
  #is an optional field that specifies the number of old ReplicaSets to retain to allow rollback. Its ideal value depends on the frequency and stability of new Deployments
  revisionHistoryLimit: 10
  #is an optional field that specifies the minimum number of seconds for which a newly created Pod should be ready without any of its containers crashing
  minReadySeconds: 10
  strategy:
    type: RollingUpdate
    rollingUpdate:
      #  is an optional field that specifies the maximum number of Pods that can be created over the desired number of Pods  recreate
      maxSurge: 30%
      #is an optional field that specifies the maximum number of Pods that can be unavailable during the update process
      maxUnavailable: 10%
  template: # create pods using pod definition in this template
    metadata:
      # unlike pod-nginx.yaml, the name is not included in the meta data as a unique name is
      # generated from the deployment name 
      # 必须和Deployment metadata配置一致
      labels:
        dcos-app: php-apache
    spec:
      containers:
      - name: php-apache
        image: k8s.gcr.io/hpa-example:latest
        ports:
        - containerPort: 80
        # defines the health checking
        resources:
          limits:
            cpu: 100m
            memory: 100Mi
          requests:
            cpu: 100m
            memory: 100Mi
```

应用服务配置为：

php-apache-svc.yaml
```
apiVersion: v1
kind: Service
metadata:
  name: php-apache
  labels:
    dcos-app: php-apache
spec:
  ports:
    - port: 80
      targetPort: 80
      # TCP/UDP default TCP
      protocol: TCP
  selector:
    dcos-app: php-apache
```

启动应用和对应的服务
```
$kubectl apply -f php-apache-deployment.yaml -n heyongjia
$kubectl apply -f php-apache-svc.yaml -n heyongjia
```

### 定义应用的cpu和内存hpa规则

下规则是cpu使用率超过30%/内存使用率超过80Mi， 就进行扩展， 最多实例数目为3，为了测试方便才设置这么低百分比，按照实际情况进行配置

php-apache-hpa.yaml:
```
apiVersion: autoscaling/v2beta1
kind: HorizontalPodAutoscaler
metadata:
 name: php-apache-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1beta1
    kind: Deployment
    name: php-apache 
  minReplicas: 1
  maxReplicas: 3
  metrics:
  - type: Resource
    resource:
      name: cpu
      targetAverageUtilization: 30
  - type: Resource
    resource:
      name: memory
      targetAverageValue: 80Mi
```

创建php-apache-hpa规则
```
$kubectl apply -f php-apache-hpa.yaml -n heyongjia
```

运行一段时间以后可以通过hpa获取当前运行状态
```
$kubectl get hpa -n heyongjia
NAME             REFERENCE               TARGETS                      MINPODS   MAXPODS   REPLICAS   AGE
php-apache-hpa   Deployment/php-apache   18927616 / 150Mi, 0% / 30%   1         3         1          2m
```

### 压力测试

启动busybox对服务进行压力测试
```
kubectl run -i --tty load-generator --image=busybox /bin/sh
$ while true; do wget -q -O- http://php-apache.default.svc.cluster.local; done
OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!OK!
```

### 获取hpa状态
    运行一段时间以后， 通过下面命令获取hpa信息， 以及deployment实例数目

获取hpa状态
```
kubectl get hpa -n heyongjia
NAME             REFERENCE               TARGETS                       MINPODS   MAXPODS   REPLICAS   AGE
php-apache-hpa   Deployment/php-apache   22126592 / 150Mi, 36% / 30%   1         3         1          16m
```


获取hpa事件
```
 kubectl describe hpa php-apache-hpa -n heyongjia
Name:                                                  php-apache-hpa
Namespace:                                             heyongjia
Labels:                                                <none>
Annotations:                                           kubectl.kubernetes.io/last-applied-configuration={"apiVersion":"autoscaling/v2beta1","kind":"HorizontalPodAutoscaler","metadata":{"annotations":{},"name":"php-apache-hpa","namespace":"heyongjia"},"spe...
CreationTimestamp:                                     Wed, 11 Jul 2018 09:29:35 +0000
Reference:                                             Deployment/php-apache
Metrics:                                               ( current / target )
  resource memory on pods:                             22093824 / 150Mi
  resource cpu on pods  (as a percentage of request):  100% (100m) / 30%
Min replicas:                                          1
Max replicas:                                          3
Conditions:
  Type            Status  Reason            Message
  ----            ------  ------            -------
  AbleToScale     False   BackoffBoth       the time since the previous scale is still within both the downscale and upscale forbidden windows
  ScalingActive   True    ValidMetricFound  the HPA was able to succesfully calculate a replica count from cpu resource utilization (percentage of request)
  ScalingLimited  True    TooManyReplicas   the desired replica count is more than the maximum replica count
Events:
  Type     Reason                        Age                From                       Message
  ----     ------                        ----               ----                       -------
  Warning  FailedGetResourceMetric       15m (x4 over 16m)  horizontal-pod-autoscaler  unable to get metrics for resource memory: no metrics returned from heapster
  Warning  FailedComputeMetricsReplicas  15m (x4 over 16m)  horizontal-pod-autoscaler  failed to get memory utilization: unable to get metrics for resource memory: no metrics returned from heapster
  Normal   SuccessfulRescale             1m                 horizontal-pod-autoscaler  New size: 2; reason: cpu resource utilization (percentage of request) a
```

获取deployment数目
```
AME             DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
load-generator   1         1         1            1           13m
php-apache       2         2         2            2           19m
```

关闭压力测试以后

deployment 实例数目变小
```
$ kubectl get deployment -n heyongjia
NAME             DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
load-generator   1         1         1            1           35m
php-apache       1         1         1            1           41m
```

hpa事件
```
$kubectl describe hpa php-apache-hpa -n heyongjia  
Name:                                                  php-apache-hpa
Namespace:                                             heyongjia
Labels:                                                <none>
Annotations:                                           kubectl.kubernetes.io/last-applied-configuration={"apiVersion":"autoscaling/v2beta1","kind":"HorizontalPodAutoscaler","metadata":{"annotations":{},"name":"php-apache-hpa","namespace":"heyongjia"},"spe...
CreationTimestamp:                                     Wed, 11 Jul 2018 09:29:35 +0000
Reference:                                             Deployment/php-apache
Metrics:                                               ( current / target )
  resource memory on pods:                             22093824 / 150Mi
  resource cpu on pods  (as a percentage of request):  0% (0) / 30%
Min replicas:                                          1
Max replicas:                                          3
Conditions:
  Type            Status  Reason              Message
  ----            ------  ------              -------
  AbleToScale     True    ReadyForNewScale    the last scale time was sufficiently old as to warrant a new scale
  ScalingActive   True    ValidMetricFound    the HPA was able to succesfully calculate a replica count from memory resource
  ScalingLimited  False   DesiredWithinRange  the desired count is within the acceptable range
Events:
  Type     Reason                        Age                From                       Message
  ----     ------                        ----               ----                       -------
  Warning  FailedGetResourceMetric       40m (x4 over 42m)  horizontal-pod-autoscaler  unable to get metrics for resource memory: no metrics returned from heapster
  Warning  FailedComputeMetricsReplicas  40m (x4 over 42m)  horizontal-pod-autoscaler  failed to get memory utilization: unable to get metrics for resource memory: no metrics returned from heapster
  Normal   SuccessfulRescale             27m                horizontal-pod-autoscaler  New size: 2; reason: cpu resource utilization (percentage of request) above target
  Normal   SuccessfulRescale             23m                horizontal-pod-autoscaler  New size: 3; reason: cpu resource utilization (percentage of request) above target
  Normal   SuccessfulRescale             17m                horizontal-pod-autoscaler  New size: 1; reason: All metrics below target
```

获取hpa状态
```
kubectl get hpa php-apache-hpa -n heyongjia 
NAME             REFERENCE               TARGETS                      MINPODS   MAXPODS   REPLICAS   AGE
php-apache-hpa   Deployment/php-apache   22093824 / 150Mi, 0% / 30%   1         3         1          43m
```

获取当前pod信息
```
kubectl get --raw apis/metrics.k8s.io/v1beta1/namespaces/heyongjia/pods/php-apache-7696967cb7-rzzqj
{"kind":"PodMetrics","apiVersion":"metrics.k8s.io/v1beta1","metadata":{"name":"php-apache-7696967cb7-rzzqj","namespace":"heyongjia","selfLink":"/apis/metrics.k8s.io/v1beta1/namespaces/heyongjia/pods/php-apache-7696967cb7-rzzqj","creationTimestamp":"2018-07-11T10:14:46Z"},"timestamp":"2018-07-11T10:14:00Z","window":"1m0s","containers":[{"name":"php-apache","usage":{"cpu":"0","memory":"21576Ki"}}]}
```
21576Ki = 21576*1024=22093824 和hpa状态值是一样的， 证明hpa正常的。
