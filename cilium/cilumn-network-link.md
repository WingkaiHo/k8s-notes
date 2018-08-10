### 安装网络测试关系工具

```
$yum install ethtool.x86_64 iproute.x86_64
```

### cilium_vxlan cilium_net cilium_health 接口关系

查询cilium_vxlan对端接口
```
$ethtool -S cilium_net
NIC statistics:
     peer_ifindex: 2716

$ip link | grep 2716
2716: cilium_host@cilium_net: <BROADCAST,MULTICAST,NOARP,UP,LOWER_UP> mtu 1450 qdisc noqueue state UP mode DEFAULT qlen 1000
```

cilium_vxlan <-----> cilium_host
 

### 在k8s上安装busybox工具
```
$kubectl get pod -n heyongjia
kubectl get pod -n heyongjia
NAME                       READY     STATUS    RESTARTS   AGE       IP              NODE
busybox1                   1/1       Running   70         5d        10.233.64.142   k8s-1
jenkins-57b4c95d9c-gmxsq   1/1       Running   0          4d        10.233.65.153   k8s-2
```

获取
ethtool -S lxcfc0e3
NIC statistics:
     peer_ifindex: 2723


kubectl run vegeta --image=oba11/vegeta --replicas=3 sleep 3000

kubectl run redis --image=redis:alpine --replicas=3 

kubectl run nginx --image=nginx:alpine --replicas=5

kubectl run iperf3 --image=networkstatic/iperf3 --replicas=3 -- iperf3 -s


host=POD_IP_ADDRESS

iperf3 -c $host

echo "GET http://$host/" | vegeta attack -duration=10s -rate=8000 | tee results.bin | vegeta report

echo "GET http://$host/" | vegeta attack -duration=10s -rate=5000 | tee results.bin | vegeta report

redis-benchmark -h $host -q -t SET,GET,LPUSH -c 5000 -n 100000 -r 100000 -d 256

作者：akka9
链接：https://www.jianshu.com/p/cfc4e62ff3ea
來源：简书
简书著作权归作者所有，任何形式的转载都请联系作者获得授权并注明出处。


## ipef3 测试网络情况

iperf3安装
iperf3下载：https://iperf.fr/iperf-download.php#fedora

yum install https://iperf.fr/download/fedora/iperf3-3.1.3-1.fc24.x86_64.rpm


服务器命令如下:
```
$ iperf3 -s
```

客户端命令
```
$ iperf3 -c <server-ip> -t 200  (200 次送)
```


```
apiVersion: apps/v1beta1
kind: Deployment
metadata:
  name: load-generator
  labels:
    dcos-app: load-generator
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
        dcos-app: load-generator
    spec:
      nodeSelector:
         kubernetes.io/hostname: node3 
      containers:
      - name: load-generator-web
        image: centos:7
        command: ["/bin/bash"]
        resources: {}
        stdin: true
        terminationMessagePath: /dev/termination-log
        terminationMessagePolicy: File
        tty: true

```

kubectl get pod -o wide
NAME                              READY     STATUS    RESTARTS   AGE       IP              NODE
load-generator-6c75fd585c-72222   1/1       Running   0          48s       10.233.64.123   node3

node2 -> node3
2.19 Gbits/sec  51068             sender
2.19 Gbits/sec                  receiver
 
node3->node2
2.25 Gbits/sec  87301             sender
2.25 Gbits/sec                  receiver



node2->容器 (容器在node3上， 应该参考node2->node3发送速度损失多少)
1.89 Gbits/sec  11725             sender
1.89 Gbits/sec                  receiver

1.89/2.19 =  0.86301369863013688  host->容器网络消耗14%

容器->node2
2.04 Gbits/sec  6505             sender
2.04 Gbits/sec                  receiver

2.04/2.25 = 0.9066666666666664  容器-> host（外部网络） 10%


kubectl get pod  -o wide
NAME                               READY     STATUS    RESTARTS   AGE       IP              NODE
load-generator-1-bccdc7c8b-j7n6p   1/1       Running   0          5m        10.233.65.72    node2
load-generator-665cd4b7b7-mmvnf    1/1       Running   0          40m       10.233.64.191   node3


容器-容器

node2 容器 -> node 3 容器

node2 容器
iperf3 -c 10.233.64.191 -t 20

node3 容器
iperf3 -s


速度
1.81 Gbits/sec  4090             sender
1.81 Gbits/sec                  receiver

1.81 / 2.19 = 0.82


node3 容器 -> node 2容器 

node2 容器
```
iperf3 -s
```

node3 容器
```
iperf3 -c 10.233.65.72 -t 20
```

Bandwidth       Retr
1.90 Gbits/sec  2616             sender
1.90 Gbits/sec                  receiver
1.90/ 2.25 = 0.84




vegeta 测试

wget https://github.com/tsenart/vegeta/releases/download/v7.0.3/vegeta-7.0.3-linux-amd64.tar.gz

node to node

export host=10.4.6.12
echo "GET http://$host/" | vegeta attack -duration=10s -rate=5000 | tee results.bin | vegeta report
Requests      [total, rate]            50000, 5000.10
Duration      [total, attack, wait]    10.000376035s, 9.999799473s, 576.562µs
Latencies     [mean, 50, 95, 99, max]  1.636296ms, 603.905µs, 5.78833ms, 16.404483ms, 77.297603ms
Bytes In      [total, mean]            185000000, 3700.00
Bytes Out     [total, mean]            0, 0.00
Success       [ratio]                  100.00%
Status Codes  [code:count]             200:50000  
Error Set:


echo "GET http://$host/" | vegeta attack -duration=10s -rate=5000 | tee results.bin | vegeta report
Requests      [total, rate]            50000, 5000.10
Duration      [total, attack, wait]    10.001606941s, 9.999799699s, 1.807242ms
Latencies     [mean, 50, 95, 99, max]  1.279369ms, 586.711µs, 4.690862ms, 9.149465ms, 28.228267ms
Bytes In      [total, mean]            185000000, 3700.00
Bytes Out     [total, mean]            0, 0.00
Success       [ratio]                  100.00%
Status Codes  [code:count]             200:50000  
Error Set:


3 实例测试

kubectl get svc 
NAME               TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)    AGE
kubernetes         ClusterIP   10.233.0.1     <none>        443/TCP    2d
nginx              ClusterIP   10.233.40.53   <none>        80/TCP     7m

node -> svc -> 3 pod
export host=10.233.40.53 
echo "GET http://$host/" | vegeta attack -duration=10s -rate=8000 | tee results.bin | vegeta report


echo "GET http://$host/" | vegeta attack -duration=10s -rate=8000 | tee results.bin | vegeta report
Requests      [total, rate]            80000, 8000.10
Duration      [total, attack, wait]    10.001625716s, 9.999874766s, 1.75095ms
Latencies     [mean, 50, 95, 99, max]  963.65µs, 372.806µs, 3.769647ms, 11.746427ms, 28.84387ms
Bytes In      [total, mean]            48960000, 612.00
Bytes Out     [total, mean]            0, 0.00
Success       [ratio]                  100.00%
Status Codes  [code:count]             200:80000  


echo "GET http://$host/" | vegeta attack -duration=10s -rate=5000 | tee results.bin | vegeta report
Requests      [total, rate]            50000, 5000.10
Duration      [total, attack, wait]    10.000115251s, 9.999799839s, 315.412µs
Latencies     [mean, 50, 95, 99, max]  544.529µs, 323.444µs, 1.549166ms, 4.922374ms, 18.411471ms
Bytes In      [total, mean]            30600000, 612.00
Bytes Out     [total, mean]            0, 0.00
Success       [ratio]                  100.00%
Status Codes  [code:count]             200:50000  
Error Set:

pod svc to pod 

 echo "GET http://$host/" | vegeta attack -duration=10s -rate=5000 | tee results.bin | vegeta report
Requests      [total, rate]            50000, 5000.10
Duration      [total, attack, wait]    10.00033344s, 9.999799715s, 533.725µs
Latencies     [mean, 50, 95, 99, max]  1.041026ms, 504.727µs, 3.751375ms, 10.589883ms, 29.614401ms
Bytes In      [total, mean]            30600000, 612.00
Bytes Out     [total, mean]            0, 0.00
Success       [ratio]                  100.00%
Status Codes  [code:count]             200:50000  
Error Set:

Requests      [total, rate]            50000, 5000.10
Duration      [total, attack, wait]    10.000550909s, 9.999799559s, 751.35µs
Latencies     [mean, 50, 95, 99, max]  1.182855ms, 469.574µs, 4.149749ms, 16.006569ms, 61.406422ms
Bytes In      [total, mean]            30600000, 612.00
Bytes Out     [total, mean]            0, 0.00
Success       [ratio]                  100.00%
Status Codes  [code:count]             200:50000 

Requests      [total, rate]            50000, 5000.10
Duration      [total, attack, wait]    10.000665581s, 9.999799656s, 865.925µs
Latencies     [mean, 50, 95, 99, max]  1.199786ms, 526.757µs, 4.253609ms, 13.494069ms, 56.489727ms
Bytes In      [total, mean]            30600000, 612.00
Bytes Out     [total, mean]            0, 0.00
Success       [ratio]                  100.00%
Status Codes  [code:count]             200:50000  
Error Set:


echo "GET http://$host/" | vegeta attack -duration=10s -rate=8000 | tee results.bin | vegeta report

Requests      [total, rate]            80000, 8000.05
Duration      [total, attack, wait]    10.000605354s, 9.999939411s, 665.943µs
Latencies     [mean, 50, 95, 99, max]  1.769322ms, 711.359µs, 6.11386ms, 18.50876ms, 66.10096ms
Bytes In      [total, mean]            48960000, 612.00
Bytes Out     [total, mean]            0, 0.00
Success       [ratio]                  100.00%
Status Codes  [code:count]             200:80000  
Error Set:


Requests      [total, rate]            80000, 8000.10
Duration      [total, attack, wait]    10.000390915s, 9.999874764s, 516.151µs
Latencies     [mean, 50, 95, 99, max]  1.508848ms, 697.551µs, 5.65144ms, 12.325069ms, 33.342072ms
Bytes In      [total, mean]            48960000, 612.00
Bytes Out     [total, mean]            0, 0.00
Success       [ratio]                  100.00%
Status Codes  [code:count]             200:80000  
Error Set:
 

单个个容器测试

选取其中一个pod
kubectl get pod -o wide
NAME                       READY     STATUS    RESTARTS   AGE       IP              NODE
nginx-666865b5dd-kqqx4     1/1       Running   0          15m       10.233.64.133   node3
nginx-666865b5dd-qpgxk     1/1       Running   0          15m       10.233.65.209   node2
nginx-666865b5dd-scfn2     1/1       Running   0          15m       10.233.66.73    node1



10.233.64.133

单个容器5000 qps

node to pod 
export host=10.233.64.133
echo "GET http://$host/" | vegeta attack -duration=10s -rate=5000 | tee results.bin | vegeta report
Requests      [total, rate]            50000, 5000.10
Duration      [total, attack, wait]    10.001152507s, 9.999799665s, 1.352842ms
Latencies     [mean, 50, 95, 99, max]  1.805996ms, 709.363µs, 6.445475ms, 13.286675ms, 48.228191ms
Bytes In      [total, mean]            30600000, 612.00
Bytes Out     [total, mean]            0, 0.00
Success       [ratio]                  100.00%
Status Codes  [code:count]             200:50000  

Requests      [total, rate]            50000, 5000.10
Duration      [total, attack, wait]    10.000256515s, 9.999799501s, 457.014µs
Latencies     [mean, 50, 95, 99, max]  1.20334ms, 549.872µs, 4.571522ms, 10.342382ms, 27.07779ms
Bytes In      [total, mean]            30600000, 612.00
Bytes Out     [total, mean]            0, 0.00
Success       [ratio]                  100.00%
Status Codes  [code:count]             200:50000  
Error Set:

Requests      [total, rate]            50000, 5000.10
Duration      [total, attack, wait]    10.000289464s, 9.999799564s, 489.9µs
Latencies     [mean, 50, 95, 99, max]  1.48525ms, 632.417µs, 5.706408ms, 11.714164ms, 32.178973ms
Bytes In      [total, mean]            30600000, 612.00
Bytes Out     [total, mean]            0, 0.00
Success       [ratio]                  100.00%
Status Codes  [code:count]             200:50000  
Error Set:

pod to pod 
echo "GET http://$host/" | vegeta attack -duration=10s -rate=5000 | tee results.bin | vegeta report
Requests      [total, rate]            50000, 5000.10
Duration      [total, attack, wait]    10.000371923s, 9.999799522s, 572.401µs
Latencies     [mean, 50, 95, 99, max]  2.660152ms, 588.268µs, 8.66143ms, 38.652452ms, 136.558798ms
Bytes In      [total, mean]            30600000, 612.00
Bytes Out     [total, mean]            0, 0.00
Success       [ratio]                  100.00%
Status Codes  [code:count]             200:50000  
Error Set:

echo "GET http://$host/" | vegeta attack -duration=10s -rate=5000 | tee results.bin | vegeta report
Requests      [total, rate]            50000, 5000.06
Duration      [total, attack, wait]    10.0013327s, 9.999880856s, 1.451844ms
Latencies     [mean, 50, 95, 99, max]  1.815985ms, 577.701µs, 7.904691ms, 17.395937ms, 113.296935ms
Bytes In      [total, mean]            30600000, 612.00
Bytes Out     [total, mean]            0, 0.00
Success       [ratio]                  100.00%
Status Codes  [code:count]             200:50000  
Error Set:

单个容器8000 qps
node to node 
echo "GET http://$host/" | vegeta attack -duration=10s -rate=8000 | tee results.bin | vegeta report
Requests      [total, rate]            80000, 7999.37
Duration      [total, attack, wait]    10.011590875s, 10.000781345s, 10.80953ms
Latencies     [mean, 50, 95, 99, max]  9.949838ms, 6.19691ms, 31.776078ms, 60.311435ms, 120.001653ms
Bytes In      [total, mean]            296000000, 3700.00
Bytes Out     [total, mean]            0, 0.00
Success       [ratio]                  100.00%
Status Codes  [code:count]             200:80000  
Error Set:

Requests      [total, rate]            80000, 8000.10
Duration      [total, attack, wait]    10.009289007s, 9.999874838s, 9.414169ms
Latencies     [mean, 50, 95, 99, max]  16.616637ms, 7.381889ms, 62.640294ms, 172.484996ms, 358.017538ms
Bytes In      [total, mean]            296000000, 3700.00
Bytes Out     [total, mean]            0, 0.00
Success       [ratio]                  100.00%
Status Codes  [code:count]             200:80000  
Error Set:

Requests      [total, rate]            80000, 8000.10
Duration      [total, attack, wait]    10.003838426s, 9.999874697s, 3.963729ms
Latencies     [mean, 50, 95, 99, max]  10.500736ms, 3.809065ms, 32.447022ms, 139.41647ms, 270.923577ms
Bytes In      [total, mean]            296000000, 3700.00
Bytes Out     [total, mean]            0, 0.00
Success       [ratio]                  100.00%
Status Codes  [code:count]             200:80000  
Error Set:


node to pod 
echo "GET http://$host/" | vegeta attack -duration=10s -rate=8000 | tee results.bin | vegeta report
Requests      [total, rate]            80000, 7998.03
Duration      [total, attack, wait]    10.004393928s, 10.002463208s, 1.93072ms
Latencies     [mean, 50, 95, 99, max]  3.710822ms, 1.5032ms, 14.801361ms, 24.761438ms, 107.202171ms
Bytes In      [total, mean]            48960000, 612.00
Bytes Out     [total, mean]            0, 0.00
Success       [ratio]                  100.00%
Status Codes  [code:count]             200:80000  
Error Set:

echo "GET http://$host/" | vegeta attack -duration=10s -rate=8000 | tee results.bin | vegeta report
Requests      [total, rate]            80000, 8000.10
Duration      [total, attack, wait]    10.006260103s, 9.999874777s, 6.385326ms
Latencies     [mean, 50, 95, 99, max]  2.867642ms, 918.27µs, 11.28816ms, 25.645907ms, 105.190994ms
Bytes In      [total, mean]            48960000, 612.00
Bytes Out     [total, mean]            0, 0.00
Success       [ratio]                  100.00%
Status Codes  [code:count]             200:80000  
Error Set:

pod to pod 

echo "GET http://$host/" | vegeta attack -duration=10s -rate=8000 | tee results.bin | vegeta report
Requests      [total, rate]            80000, 7999.98
Duration      [total, attack, wait]    10.002358063s, 10.000026164s, 2.331899ms
Latencies     [mean, 50, 95, 99, max]  4.653036ms, 1.373716ms, 17.165483ms, 53.72236ms, 147.552447ms
Bytes In      [total, mean]            48960000, 612.00
Bytes Out     [total, mean]            0, 0.00
Success       [ratio]                  100.00%
Status Codes  [code:count]             200:80000  
Error Set:

Requests      [total, rate]            80000, 8000.07
Duration      [total, attack, wait]    10.004501595s, 9.99991003s, 4.591565ms
Latencies     [mean, 50, 95, 99, max]  4.468891ms, 1.145203ms, 15.049106ms, 78.62788ms, 167.251169ms
Bytes In      [total, mean]            48960000, 612.00
Bytes Out     [total, mean]            0, 0.00
Success       [ratio]                  100.00%
Status Codes  [code:count]             200:80000  
Error Set:

Requests      [total, rate]            50000, 5000.10
Duration      [total, attack, wait]    10.000272092s, 9.999799857s, 472.235µs
Latencies     [mean, 50, 95, 99, max]  1.217823ms, 572.505µs, 4.136287ms, 10.300983ms, 33.773215ms
Bytes In      [total, mean]            30600000, 612.00
Bytes Out     [total, mean]            0, 0.00
Success       [ratio]                  100.00%
Status Codes  [code:count]             200:50000

redis 测试
redis-benchmark 可用从安装redis机器拷贝过来使用

打开ulimit
```
ulimit -n 10000
```


host -> host redis 
redis-benchmark -h $host -q -t SET,GET,LPUSH -c 5000 -n 100000 -r 100000 -d 256
SET: 28843.38 requests per second
GET: 26609.90 requests per second
LPUSH: 24838.55 requests per second

单个容器

host -> 容器
kubectl get pod -o wide
NAME                       READY     STATUS    RESTARTS   AGE       IP              NODE
redis-b49bf6977-n57pv      1/1       Running   0          1m        10.233.65.4     node2

export host=10.233.65.4
redis-benchmark -h $host -q -t SET,GET,LPUSH -c 5000 -n 100000 -r 100000 -d 256
SET: 23872.04 requests per second      0.827
GET: 23255.81 requests per second      0.873
LPUSH: 22301.52 requests per second    0.897


host->svc ip -> 容器
kubectl get svc
NAME               TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)    AGE
kubernetes         ClusterIP   10.233.0.1     <none>        443/TCP    2d
redis              ClusterIP   10.233.42.73   <none>        6379/TCP   2m


export host=10.233.42.73
redis-benchmark -h $host -q -t SET,GET,LPUSH -c 5000 -n 100000 -r 100000 -d 256
SET: 24366.47 requests per second      0.844
GET: 23004.37 requests per second      0.864
LPUSH: 23758.61 requests per second    0.956


pod -> pod 
redis-benchmark -h $host -q -t SET,GET,LPUSH -c 5000 -n 100000 -r 100000 -d 256
SET: 27964.21 requests per second
GET: 27427.32 requests per second
LPUSH: 26867.28 requests per second

pod -> svc -> pod
redis-benchmark -h $host -q -t SET,GET,LPUSH -c 5000 -n 100000 -r 100000 -d 256

SET: 26116.48 requests per second
GET: 28409.09 requests per second
LPUSH: 28433.32 requests per second


上面测试可能有网络波动， 但是svc（ipvs）通损失比较少

配置策略
```
apiVersion: "cilium.io/v2"
kind: CiliumNetworkPolicy
metadata:
  name: "l4-rule"
spec:
  endpointSelector:
    matchLabels:
      app: redis
  egress:
    - toPorts:
      - ports:
        - port: "80"
          protocol: TCP
```

root@redis-b49bf6977-n57pv:/data# telnet 10.4.6.13 2379
Trying 10.4.6.13...
Connected to 10.4.6.13.
Escape character is '^]'.
^]
telnet> quit
Connection closed.
root@redis-b49bf6977-n57pv:/data# telnet 10.4.6.13 2379
Trying 10.4.6.13...
^C
root@redis-b49bf6977-n57pv:/data# telnet 123.58.180.7 80
Trying 123.58.180.7...
Connected to 123.58.180.7.
Escape character is '^]'.
^]
telnet> quit
Connection closed.


路由表

2.27 Gbits/sec  92893             sender
2.27 Gbits/sec                  receiver

2.27 Gbits/sec  92893             sender
2.27 Gbits/sec                  receiver
```
[heyongjia@k8s-node-215 ~]$ route -n
Kernel IP routing table
Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
0.0.0.0         172.25.52.30    0.0.0.0         UG    0      0        0 ib0
10.233.78.192   172.25.52.130   255.255.255.192 UG    0      0        0 tunl0
10.233.103.64   172.25.52.216   255.255.255.192 UG    0      0        0 tunl0
10.233.117.0    0.0.0.0         255.255.255.192 U     0      0        0 *
10.233.117.6    0.0.0.0         255.255.255.255 UH    0      0        0 calic60f88b35dd
10.233.117.9    0.0.0.0         255.255.255.255 UH    0      0        0 calie326818f545
10.233.117.10   0.0.0.0         255.255.255.255 UH    0      0        0 cali1a72b2b8e96
10.233.117.16   0.0.0.0         255.255.255.255 UH    0      0        0 cali5f434bd5477
10.233.117.20   0.0.0.0         255.255.255.255 UH    0      0        0 calia13f5054bde
10.233.117.21   0.0.0.0         255.255.255.255 UH    0      0        0 cali3fcce899f39
10.233.117.23   0.0.0.0         255.255.255.255 UH    0      0        0 calib43069bec9d
10.233.117.25   0.0.0.0         255.255.255.255 UH    0      0        0 cali4bc7bca16cf
10.233.117.26   0.0.0.0         255.255.255.255 UH    0      0        0 caliedb6527cbcf
10.233.117.30   0.0.0.0         255.255.255.255 UH    0      0        0 calidbee8ddcc17
10.233.117.31   0.0.0.0         255.255.255.255 UH    0      0        0 cali147859d8941
10.233.117.36   0.0.0.0         255.255.255.255 UH    0      0        0 cali91b24db817f
10.233.117.56   0.0.0.0         255.255.255.255 UH    0      0        0 calib6055ed11e1
10.233.117.57   0.0.0.0         255.255.255.255 UH    0      0        0 calie2fc1a03266
10.233.117.58   0.0.0.0         255.255.255.255 UH    0      0        0 cali8614ee577e3
10.233.117.59   0.0.0.0         255.255.255.255 UH    0      0        0 cali85a5cf1b488
10.233.117.61   0.0.0.0         255.255.255.255 UH    0      0        0 calic7a86cbca3d
10.233.117.63   0.0.0.0         255.255.255.255 UH    0      0        0 cali2e1adb5ed41
```

calico


node2 -> node3
2.24 Gbits/sec  89434             sender
2.24 Gbits/sec                  receiver


node3->node2
2.33 Gbits/sec  57567             sender
2.33 Gbits/sec                  receiver

kubectl get pod  -o wide
NAME                              READY     STATUS    RESTARTS   AGE       IP             NODE
load-generator-7d4d69c88f-wtq27   1/1       Running   0          13h       10.233.71.13   node3



node2->容器 (容器在node3上， 应该参考node2->node3发送速度损失多少)
2.12 Gbits/sec  2716             sender
2.12 Gbits/sec                  receiver

2.12/2.24 =  0.94  host->容器网络消耗6%

容器->node2
2.33 Gbits/sec  54956             sender
2.33 Gbits/sec                  receiver

2.33/2.33 = 100%  容器-> host（外部网络） 100%

```
$ kubectl get pod  -o wide
NAME                                READY     STATUS    RESTARTS   AGE       IP             NODE
load-generator-1-547f8bddbf-xxwtd   1/1       Running   0          1m        10.233.75.1    node2
load-generator-7d4d69c88f-wtq27     1/1       Running   0          13h       10.233.71.13   node3
```

容器-容器

node2 容器 -> node 3 容器

node2 容器
iperf3 -c 10.233.71.13 -t 20

node3 容器
iperf3 -s


速度
2.10 Gbits/sec  3644             sender
2.10 Gbits/sec                  receiver

2.08 / 2.24 = 0.92 


node3 容器 -> node 2容器 

node2 容器
```
iperf3 -s
```

node3 容器
```
iperf3 -c 10.233.75.1 -t 20
```

Bandwidth       Retr
2.00 Gbits/sec  3376             sender
2.00 Gbits/sec                  receiver

2.0 / 2.33 = 0.85


vegeta 测试

wget https://github.com/tsenart/vegeta/releases/download/v7.0.3/vegeta-7.0.3-linux-amd64.tar.gz


node->node 
exprot host=10.5.7.13
echo "GET http://$host/" | vegeta attack -duration=10s -rate=5000 | tee results.bin | vegeta report
Requests      [total, rate]            2740, 5001.83
Duration      [total, attack, wait]    548.554779ms, 547.799545ms, 755.234µs
Latencies     [mean, 50, 95, 99, max]  548.057µs, 441.039µs, 1.140694ms, 2.191632ms, 4.785372ms
Bytes In      [total, mean]            10138000, 3700.00
Bytes Out     [total, mean]            0, 0.00
Success       [ratio]                  100.00%
Status Codes  [code:count]             200:2740  
Error Set:


echo "GET http://$host/" | vegeta attack -duration=10s -rate=8000 | tee results.bin | vegeta report
requests      [total, rate]            2739, 7997.09
Duration      [total, attack, wait]    342.853498ms, 342.499595ms, 353.903µs
Latencies     [mean, 50, 95, 99, max]  1.001374ms, 602.982µs, 3.083224ms, 4.624111ms, 7.678336ms
Bytes In      [total, mean]            10134300, 3700.00
Bytes Out     [total, mean]            0, 0.00
Success       [ratio]                  100.00%
Status Codes  [code:count]             200:2739  



kubectl get pod -o wide
NAME                       READY     STATUS    RESTARTS   AGE       IP               NODE
nginx-8686b7f655-ggm4p     1/1       Running   0          3m        10.233.102.132   node1
nginx-8686b7f655-rvqzm     1/1       Running   0          3m        10.233.71.16     node3
nginx-8686b7f655-wvxhd     1/1       Running   0          3m        10.233.75.3      node2


kubectl get svc 
NAME               TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
kubernetes         ClusterIP   10.233.0.1      <none>        443/TCP    15h
nginx              ClusterIP   10.233.52.80    <none>        80/TCP     46s
podinfo-nodeport   ClusterIP   10.233.32.211   <none>        9898/TCP   14h


kubectl get svc -o wide
NAME               TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE       SELECTOR
kubernetes         ClusterIP   10.233.0.1      <none>        443/TCP    15h       <none>
nginx              ClusterIP   10.233.52.80    <none>        80/TCP     50s       app=nginx

svc 负载均衡：
exprot host=10.233.52.80
echo "GET http://$host/" | vegeta attack -duration=10s -rate=5000 | tee results.bin | vegeta report
Requests      [total, rate]            50000, 5000.10
Duration      [total, attack, wait]    10.000326915s, 9.999799663s, 527.252µs
Latencies     [mean, 50, 95, 99, max]  1.281058ms, 560.12µs, 4.556753ms, 8.70804ms, 207.832028ms
Bytes In      [total, mean]            30600000, 612.00
Bytes Out     [total, mean]            0, 0.00
Success       [ratio]                  100.00%
Status Codes  [code:count]             200:50000
Error Set:

Requests      [total, rate]            15730, 5000.32
Duration      [total, attack, wait]    3.146165974s, 3.145799596s, 366.378µs
Latencies     [mean, 50, 95, 99, max]  788.765µs, 533.583µs, 1.946607ms, 5.340957ms, 18.01269ms
Bytes In      [total, mean]            9626760, 612.00
Bytes Out     [total, mean]            0, 0.00
Success       [ratio]                  100.00%
Status Codes  [code:count]             200:15730  
Error Set:


echo "GET http://$host/" | vegeta attack -duration=10s -rate=5000 | tee results.bin | vegeta report
Requests      [total, rate]            15730, 5000.32
Duration      [total, attack, wait]    3.148346958s, 3.145799575s, 2.547383ms
Latencies     [mean, 50, 95, 99, max]  979.982µs, 570.675µs, 3.134645ms, 6.637036ms, 15.275437ms
Bytes In      [total, mean]            9626760, 612.00
Bytes Out     [total, mean]            0, 0.00
Success       [ratio]                  100.00%
Status Codes  [code:count]             200:15730  
Error Set:


exprot host=10.233.52.80
echo "GET http://$host/" | vegeta attack -duration=10s -rate=8000 | tee results.bin | vegeta report
Requests      [total, rate]            80000, 8000.10
Duration      [total, attack, wait]    10.001106537s, 9.999874679s, 1.231858ms
Latencies     [mean, 50, 95, 99, max]  1.106539ms, 615.542µs, 3.236839ms, 8.494214ms, 35.635664ms
Bytes In      [total, mean]            48960000, 612.00
Bytes Out     [total, mean]            0, 0.00
Success       [ratio]                  100.00%
Status Codes  [code:count]             200:80000  
Error Set:

Requests      [total, rate]            15732, 8000.50
Duration      [total, attack, wait]    1.966886947s, 1.966377703s, 509.244µs
Latencies     [mean, 50, 95, 99, max]  1.325314ms, 782.036µs, 3.764987ms, 9.896772ms, 20.342806ms
Bytes In      [total, mean]            9627984, 612.00
Bytes Out     [total, mean]            0, 0.00
Success       [ratio]                  100.00%
Status Codes  [code:count]             200:15732  
Error Set:


单个容器:
选取node3 nginx pod ip 10.233.71.16
export host=10.233.71.16

echo "GET http://$host" | vegeta attack -duration=10s -rate=5000 | tee results.bin | vegeta report
Requests      [total, rate]            15730, 5000.32
Duration      [total, attack, wait]    3.146451s, 3.14579968s, 651.32µs
Latencies     [mean, 50, 95, 99, max]  967.338µs, 541.595µs, 3.29255ms, 7.735203ms, 19.064396ms
Bytes In      [total, mean]            9626760, 612.00
Bytes Out     [total, mean]            0, 0.00
Success       [ratio]                  100.00%
Status Codes  [code:count]             200:15730  
Error Set:

Requests      [total, rate]            15730, 5000.00
Duration      [total, attack, wait]    3.146365978s, 3.14599959s, 366.388µs
Latencies     [mean, 50, 95, 99, max]  580.168µs, 458.278µs, 1.033183ms, 3.66423ms, 9.089229ms
Bytes In      [total, mean]            9626760, 612.00
Bytes Out     [total, mean]            0, 0.00
Success       [ratio]                  100.00%
Status Codes  [code:count]             200:15730 


echo "GET http://$host/" | vegeta attack -duration=10s -rate=8000 | tee results.bin | vegeta report
Requests      [total, rate]            80000, 8000.10
Duration      [total, attack, wait]    10.007782084s, 9.999874659s, 7.907425ms
Latencies     [mean, 50, 95, 99, max]  5.190092ms, 767.847µs, 15.261155ms, 118.446263ms, 245.366498ms
Bytes In      [total, mean]            48821076, 610.26
Bytes Out     [total, mean]            0, 0.00
Success       [ratio]                  99.72%
Status Codes  [code:count]             200:79773  0:227  
Error Set:
Get http://10.233.71.16/: dial tcp 0.0.0.0:0->10.233.71.16:80: socket: too many open files

echo "GET http://10.233.71.16/" | vegeta attack -duration=10s -rate=8000 | tee results.bin | vegeta report
Requests      [total, rate]            15729, 8000.51
Duration      [total, attack, wait]    1.96643141s, 1.965999645s, 431.765µs
Latencies     [mean, 50, 95, 99, max]  2.150725ms, 858.717µs, 8.072963ms, 18.067041ms, 30.740413ms
Bytes In      [total, mean]            9626148, 612.00
Bytes Out     [total, mean]            0, 0.00
Success       [ratio]                  100.00%
Status Codes  [code:count]             200:15729


Requests      [total, rate]            15725, 8000.51
Duration      [total, attack, wait]    1.965981408s, 1.96549956s, 481.848µs
Latencies     [mean, 50, 95, 99, max]  15.274587ms, 1.082469ms, 99.99509ms, 153.896985ms, 219.695507ms
Bytes In      [total, mean]            9623700, 612.00
Bytes Out     [total, mean]            0, 0.00
Success       [ratio]                  100.00%
Status Codes  [code:count]             200:15725  
Error Set:

Requests      [total, rate]            15734, 7996.88
Duration      [total, attack, wait]    1.968472861s, 1.967518427s, 954.434µs
Latencies     [mean, 50, 95, 99, max]  1.864674ms, 719.293µs, 7.658397ms, 17.266349ms, 32.287029ms
Bytes In      [total, mean]            9629208, 612.00
Bytes Out     [total, mean]            0, 0.00
Success       [ratio]                  100.00%
Status Codes  [code:count]             200:15734  
Error Set:


pod -> pod 
kubectl get pod -o wide
NAME                                READY     STATUS    RESTARTS   AGE       IP               NODE
load-generator-1-547f8bddbf-rfqw8   1/1       Running   0          1m        10.233.75.4      node2
nginx-8686b7f655-ggm4p              1/1       Running   0          26m       10.233.102.132   node1
nginx-8686b7f655-rvqzm              1/1       Running   0          26m       10.233.71.16     node3
nginx-8686b7f655-wvxhd              1/1       Running   0          26m       10.233.75.3      node2
podinfo-786d47dcb8-2gmbv            1/1       Running   1          15h       10.233.71.9      node3

pod (10.233.75.4) -> pod (10.233.75.3)

exeport host=10.233.75.3

echo "GET http://$host" | vegeta attack -duration=10s -rate=5000 | tee results.bin | vegeta report
Requests      [total, rate]            50000, 5000.10
Duration      [total, attack, wait]    10.002535571s, 9.99979968s, 2.735891ms
Latencies     [mean, 50, 95, 99, max]  1.110157ms, 353.013µs, 4.900782ms, 11.771345ms, 79.077451ms
Bytes In      [total, mean]            30600000, 612.00
Bytes Out     [total, mean]            0, 0.00
Success       [ratio]                  100.00%
Status Codes  [code:count]             200:50000  
Error Set:

Requests      [total, rate]            50000, 5000.10
Duration      [total, attack, wait]    10.000733204s, 9.999799573s, 933.631µs
Latencies     [mean, 50, 95, 99, max]  1.058179ms, 536.306µs, 3.387399ms, 9.286814ms, 43.063496ms
Bytes In      [total, mean]            30600000, 612.00
Bytes Out     [total, mean]            0, 0.00
Success       [ratio]                  100.00%
Status Codes  [code:count]             200:50000  
Error Set:

export host=10.233.102.132
[root@load-generator-1-547f8bddbf-rfqw8 /]# echo "GET http://$host" | vegeta attack -duration=10s -rate=8000 | tee results.bin | vegeta report
Requests      [total, rate]            80000, 8000.10
Duration      [total, attack, wait]    10.001312896s, 9.999874649s, 1.438247ms
Latencies     [mean, 50, 95, 99, max]  6.991686ms, 953.525µs, 39.793381ms, 111.385908ms, 450.465651ms
Bytes In      [total, mean]            48960000, 612.00
Bytes Out     [total, mean]            0, 0.00
Success       [ratio]                  100.00%
Status Codes  [code:count]             200:80000  
Error Set:
echo "GET http://$host" | vegeta attack -duration=10s -rate=8000 | tee results.bin | vegeta report
Requests      [total, rate]            80000, 7896.63
Duration      [total, attack, wait]    31.176336164s, 10.130899801s, 21.045436363s
Latencies     [mean, 50, 95, 99, max]  2.235882813s, 2.086291464s, 4.460275059s, 6.428205866s, 22.347456891s
Bytes In      [total, mean]            9978660, 124.73
Bytes Out     [total, mean]            0, 0.00
Success       [ratio]                  20.38%
Status Codes  [code:count]             0:63695  200:16305  
Error Set:
Get http://10.233.102.132: EOF
Get http://10.233.102.132: http: server closed idle connection
Get http://10.233.102.132: dial tcp 0.0.0.0:0->10.233.102.132:80: socket: too many open files
Get http://10.233.102.132: read tcp 10.233.75.4:33925->10.233.102.132:80: read: connection reset by peer
Get http://10.233.102.132: read tcp 10.233.75.4:44339->10.233.102.132:80: read: connection reset by peer
Get http://10.233.102.132: read tcp 10.233.75.4:34523->10.233.102.132:80: read: connection reset by peer
Get http://10.233.102.132: read tcp 10.233.75.4:41265->10.233.102.132:80: read: connection reset by peer
Get http://10.233.102.132: read tcp 10.233.75.4:41797->10.233.102.132:80: read: connection reset by peer
Get http://10.233.102.132: read tcp 10.233.75.4:43367->10.233.102.132:80: read: connection reset by peer
Get http://10.233.102.132: read tcp 10.233.75.4:59005->10.233.102.132:80: read: connection reset by peer
Get http://10.233.102.132: read tcp 10.233.75.4:53873->10.233.102.132:80: read: connection reset by peer
Get http://10.233.102.132: read tcp 10.233.75.4:57833->10.233.102.132:80: read: connection reset by peer
Get http://10.233.102.132: read tcp 10.233.75.4:40473->10.233.102.132:80: read: connection reset by peer
Get http://10.233.102.132: read tcp 10.233.75.4:57259->10.233.102.132:80: read: connection reset by peer
....


pod -> svc -> 3 pod 

echo "GET http://$host/" | vegeta attack -duration=10s -rate=5000 | tee results.bin | vegeta report
Requests      [total, rate]            50000, 5000.10
Duration      [total, attack, wait]    10.000602603s, 9.999799631s, 802.972µs
Latencies     [mean, 50, 95, 99, max]  931.054µs, 533.877µs, 2.3913ms, 7.579427ms, 48.296446ms
Bytes In      [total, mean]            30600000, 612.00
Bytes Out     [total, mean]            0, 0.00
Success       [ratio]                  100.00%
Status Codes  [code:count]             200:50000  
Error Set:
[root@load-generator-1-547f8bddbf-rfqw8 /]# echo "GET http://$host/" | vegeta attack -duration=10s -rate=8000 | tee results.bin | vegeta report
Requests      [total, rate]            80000, 8000.08
Duration      [total, attack, wait]    10.007473492s, 9.999900676s, 7.572816ms
Latencies     [mean, 50, 95, 99, max]  2.085452ms, 1.105045ms, 6.281065ms, 12.158943ms, 60.075474ms
Bytes In      [total, mean]            48960000, 612.00
Bytes Out     [total, mean]            0, 0.00
Success       [ratio]                  100.00%
Status Codes  [code:count]             200:80000  
Error Set:
[root@load-generator-1-547f8bddbf-rfqw8 /]# echo "GET http://$host/" | vegeta attack -duration=10s -rate=8000 | tee results.bin | vegeta report
Requests      [total, rate]            80000, 8000.07
Duration      [total, attack, wait]    10.000588197s, 9.999916793s, 671.404µs
Latencies     [mean, 50, 95, 99, max]  1.315306ms, 762.587µs, 4.031404ms, 9.658555ms, 32.517758ms
Bytes In      [total, mean]            48960000, 612.00
Bytes Out     [total, mean]            0, 0.00
Success       [ratio]                  100.00%
Status Codes  [code:count]             200:80000  
Error Set:

echo "GET http://$host/" | vegeta attack -duration=10s -rate=8000 | tee results.bin | vegeta report
Requests      [total, rate]            80000, 7988.87
Duration      [total, attack, wait]    10.24947533s, 10.013932532s, 235.542798ms
Latencies     [mean, 50, 95, 99, max]  17.47847ms, 1.148069ms, 145.736959ms, 314.74493ms, 631.67726ms
Bytes In      [total, mean]            48946536, 611.83
Bytes Out     [total, mean]            0, 0.00
Success       [ratio]                  99.97%
Status Codes  [code:count]             200:79978  0:22  
Error Set:
Get http://10.233.4.55/: http: server closed idle connection
Get http://10.233.4.55/: EOF

redis 测试

host2 -> host3(redis)

export host=10.5.7.13
redis-benchmark -h $host -q -t SET,GET,LPUSH -c 5000 -n 100000 -r 100000 -d 256
SET: 27442.37 requests per second
GET: 28943.56 requests per second
LPUSH: 25819.78 requests per second



kubectl get pod -o wide
NAME                                READY     STATUS    RESTARTS   AGE       IP             NODE
load-generator-1-547f8bddbf-rfqw8   1/1       Running   0          44m       10.233.75.4    node2
podinfo-786d47dcb8-2gmbv            1/1       Running   1          16h       10.233.71.9    node3
redis-b49bf6977-j4fld               1/1       Running   0          3m        10.233.71.19   node3


node -> pod 
export host=10.233.71.19
redis-benchmark -h $host -q -t SET,GET,LPUSH -c 5000 -n 100000 -r 100000 -d 256

SET: 25081.52 requests per second
GET: 24563.99 requests per second
LPUSH: 24912.80 requests per second

SET: 26595.74 requests per second
GET: 28232.64 requests per second
LPUSH: 28208.74 requests per second

host->svc ip -> 容器
kubectl get svc
NAME               TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)    AGn
redis              ClusterIP   10.233.14.230   <none>        6379/TCP   11m


export host=10.233.14.230
redis-benchmark -h $host -q -t SET,GET,LPUSH -c 5000 -n 100000 -r 100000 -d 256

多次测试 calico 下ipvs转发 效果不如直接calico ip通信

SET: 24319.07 requests per second     
GET: 25654.18 requests per second     
LPUSH: 25106.70 requests per second   

SET: 25258.90 requests per second      
GET: 23288.31 requests per second     
LPUSH: 24437.93 requests per second  


SET: 24189.65 requests per second
GET: 23707.92 requests per second
LPUSH: 24055.81 requests per second 

上面测试可能有网络波动， 但是svc（ipvs）通损失比较少


pod -> redis pod 

host2 pod -> host3 redis pod
SET: 27262.81 requests per second
GET: 26831.23 requests per second
LPUSH: 27487.63 requests per second


host pod -> svc host3 redis pod
SET: 23590.47 requests per second
GET: 22841.48 requests per second
LPUSH: 25406.50 requests per second



