## Metrics
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
- http://master-ip:8080/apis/metrics.k8s.io/v1beta1/nodes
- http://master-ip:8080/apis/metrics.k8s.io/v1beta1/nodes/<node-name>
- http://master-ip:8080/apis/metrics.k8s.io/v1beta1/pods
- http://master:8080/apis/metrics.k8s.io/v1beta1/namespace/<namespace-name>/pods/<pod-name>
也可以直接通过 kubectl 命令来访问这些 API，比如
- kubectl get --raw apis/metrics.k8s.io/v1beta1/nodes
- kubectl get --raw apis/metrics.k8s.io/v1beta1/pods
- kubectl get --raw apis/metrics.k8s.io/v1beta1/nodes/<node-name>
- kubectl get --raw apis/metrics.k8s.io/v1beta1/namespace/<namespace-name>/pods/<pod-name>

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

