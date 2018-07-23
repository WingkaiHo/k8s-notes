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


kubectl get svc 
NAME               TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)    AGE
kubernetes         ClusterIP   10.233.0.1     <none>        443/TCP    2d
nginx              ClusterIP   10.233.40.53   <none>        80/TCP     7m


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


当个容器测试

选取其中一个pod
kubectl get pod -o wide
NAME                       READY     STATUS    RESTARTS   AGE       IP              NODE
nginx-666865b5dd-kqqx4     1/1       Running   0          15m       10.233.64.133   node3
nginx-666865b5dd-qpgxk     1/1       Running   0          15m       10.233.65.209   node2
nginx-666865b5dd-scfn2     1/1       Running   0          15m       10.233.66.73    node1



10.233.64.133

单个容器5000 qps
export host=10.233.64.133
echo "GET http://$host/" | vegeta attack -duration=10s -rate=5000 | tee results.bin | vegeta report
Requests      [total, rate]            50000, 5000.10
Duration      [total, attack, wait]    10.001152507s, 9.999799665s, 1.352842ms
Latencies     [mean, 50, 95, 99, max]  1.805996ms, 709.363µs, 6.445475ms, 13.286675ms, 48.228191ms
Bytes In      [total, mean]            30600000, 612.00
Bytes Out     [total, mean]            0, 0.00
Success       [ratio]                  100.00%
Status Codes  [code:count]             200:50000  



单个容器8000 qps
echo "GET http://$host/" | vegeta attack -duration=10s -rate=8000 | tee results.bin | vegeta report
Requests      [total, rate]            80000, 7998.03
Duration      [total, attack, wait]    10.004393928s, 10.002463208s, 1.93072ms
Latencies     [mean, 50, 95, 99, max]  3.710822ms, 1.5032ms, 14.801361ms, 24.761438ms, 107.202171ms
Bytes In      [total, mean]            48960000, 612.00
Bytes Out     [total, mean]            0, 0.00
Success       [ratio]                  100.00%
Status Codes  [code:count]             200:80000  
Error Set:


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
