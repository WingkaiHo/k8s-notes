
### ETCD集群大小与容错

  集群的大小指集群节点的个数。根据`etcd`的分布式数据冗余策略，集群节点越多，容错能力(Failure Tolerance)越强，同时写性能也会越差。 所以关于集群大小的优化，其实就是容错和写性能的一个平衡。
  另外， etcd 推荐使用 奇数 作为集群节点个数。因为奇数个节点与和其配对的偶数个节点相比(比如 3节点和4节点对比)，
容错能力相同，却可以少一个节点。
  所以综合考虑性能和容错能力，etcd 官方文档推荐的 etcd 集群大小是 3, 5, 7。至于到底选择 3,5 还是 7，根据需要的容错能力而定。

| cluser size | MAJORITY | FAILURE TOLERANCE |
|--------|--------|--------|
|   1    |   1    |  0     |
|   3    |   2    |  1     |
|   5    |   3    |  2     |
|   7    |   4    |  3     |
|   9    |   5    |  4     |


### ETCD 集群参数

#### 修改Etcd 默认存储限制

   etcd 默认存储限制为 2GB，可以通过 --quota-backend-bytes 选项增大。最大8GB. 

#### 磁盘优化（官方）

etcd集群对磁盘延迟非常敏感。由于etcd必须将提议持久保存到其日志中，因此来自其他进程的磁盘活动可能会导致长时间fsync延迟。结果是etcd可能会错过心跳，导致请求超时和临时领导者丢失。当给定高磁盘优先级时，etcd服务器有时可以稳定地与这些进程一起运行。

在Linux上，etcd的磁盘优先级可以配置为ionice：
```
# best effort, highest priority
$ sudo ionice -c2 -n0 -p `pgrep etcd`
```

建议使用本地ssd盘

#### 时间参数（官方）

适当调整心跳，选举超时， kubespary已经相关调整
```
ETCD_HEARTBEAT_INTERVAL=250 (ms)
ETCD_ELECTION_TIMEOUT=5000  (ms)
```

### etcd 日常维护

### etcd 查询节点健康情况

```
etcdctl --endpoints=${ETCD_ENDPOINTS} --cacert=/etc/ssl/etcd/ssl/ca.pem --cert=/etc/ssl/etcd/ssl/node-node1.pem --key=/etc/ssl/etcd/ssl/node-node1-key.pem  endpoint health
https://10.5.7.11:2379 is healthy: successfully committed proposal: took = 1.637728ms
https://10.5.7.12:2379 is healthy: successfully committed proposal: took = 1.931442ms
https://10.5.7.13:2379 is healthy: successfully committed proposal: took = 1.923884ms
```


### 删除有问题etcd节点

  etcd节点硬件出现需要替换，长时间无法修复才可以进行删除对应etcd节点， 因为apiserver使用etcd节点， 所有网络控件也使用etcd节点， 平时etcd节点尽量不去修改替代工作，否则需要大量组件重新启动改造成不稳定。

下面命令删除etcd节点
```
etcdctl --endpoints=${ETCD_ENDPOINTS} --cacert=/etc/ssl/etcd/ssl/ca.pem --cert=/etc/ssl/etcd/ssl/node-node1.pem --key=/etc/ssl/etcd/ssl/node-node1-key.pem  member list    
1e315dba8e002c2a, started, etcd3, https://10.5.7.13:2380, https://10.5.7.13:2379
37d40b1718d800ce, started, etcd2, https://10.5.7.12:2380, https://10.5.7.12:2379
7dfd6eec90dd56f5, started, etcd1, https://10.5.7.11:2380, https://10.5.7.11:2379
[root@node1 ~]# etcdctl --endpoints=${ETCD_ENDPOINTS} --cacert=/etc/ssl/etcd/ssl/ca.pem --cert=/etc/ssl/etcd/ssl/node-node1.pem --key=/etc/ssl/etcd/ssl/node-node1-key.pem  member remove etcd2 
Error:  bad member ID arg (strconv.ParseUint: parsing "etcd2": invalid syntax), expecting ID in Hex
[root@node1 ~]# etcdctl --endpoints=${ETCD_ENDPOINTS} --cacert=/etc/ssl/etcd/ssl/ca.pem --cert=/etc/ssl/etcd/ssl/node-node1.pem --key=/etc/ssl/etcd/ssl/node-node1-key.pem  member remove 37d40b1718d800ce 
Member 37d40b1718d800ce removed from cluster 26458204a0dd6ea6
```

通过kubespray 在etcd集群执行删除操作以后，需要通过kubespary 更新到master和网络组件上， 下面host.ini增加新etcd, 替换旧etcd节点
```
修改之前
[etcd]
node1
node2
node3


[vault]
node1
node2
node3

删除node2， 添加node4
[etcd]
node1
node4
node3


[vault]
node1
node4
node3

#etcd 和 valult 两个group 必须一致
```
修改完毕`host.int`执行下面命令：

```
$ansible -i inventory/calico-cluster/hosts.ini  all -m setup -b --become-user=root
```

更新集群, 网络组件/master组件需要访问etcd

```
ansible-playbook -b --become-user=root -i inventory/calico-cluster/hosts.ini cluster.yml
```


### etcd 备份和恢复

参考： https://www.mirantis.com/blog/everything-you-ever-wanted-to-know-about-using-etcd-with-kubernetes-v1-6-but-were-afraid-to-ask/

  这里介绍calico使用etcd v2 api / kubernetes 使用etcd v3版本api， 目前我们使用etcd3.2.3版本, 通过v2版本备份数据恢复失败。目前已经尝试使用calico v3.1 / cilium v1.1 版本， 网络组件和kubernetes集群统一使用etcd v3 版本api保存数据。  


#### etcd数据库备份命令
```
$ export ETCD_ENDPOINTS=https://10.4.6.11:2379,https://10.4.6.12:2379,https://10.4.6.13:2379
$ export ETCDCTL_API=3 
$ etcdctl --endpoints=${ETCD_ENDPOINTS} --cacert=/etc/ssl/etcd/ssl/ca.pem --cert=/etc/ssl/etcd/ssl/node-node2.pem --key=/etc/ssl/etcd/ssl/node-node2-key.pem  snapshot save  etcd-data-20180801.db
```

  建议在生产环境通过部署自动备份etcd组件每半个小时～一个小时备份etcd数据库， 组件申请rbd volume把备份数据库存放在rbd上， 以便集群崩溃以后可以恢复数据。

#### 数据库恢复
   etcd数据库通过备份恢复数据， 这个操作在集群数据丢失/不可用情况下才执行的，因为需要停止集群：

1） 停止所有etcd集群的所有节点
2） 清理数据目录例如 /var/lib/etcd/
3)  把恢复文件拷贝各个节点上，
4） 需要在etcd集群所有机器都执行
5） 重新启动所有节点etcd

相关命令:
```
$ systemctl stop etcd
$ source /etc/etcd.env
$ mv $ETCD_DATA_DIR  $ETCD_DATA_DIR-backup
$ export ETCDCTL_API=3 
$ ETCDCTL_API=3 etcdctl snapshot restore BACKUP_FILE \
--name $ETCD_NAME--initial-cluster "$ETCD_INITIAL_CLUSTER" \
--initial-cluster-token "$ETCD_INITIAL_CLUSTER_TOKEN" \
--initial-advertise-peer-urls $ETCD_INITIAL_ADVERTISE_PEER_URLS \
--data-dir $ETCD_DATA_DIR 
```

### 列举 etcd数据
```
etcdctl --endpoints=${ETCD_ENDPOINTS} --cacert=/etc/ssl/etcd/ssl/ca.pem --cert=/etc/ssl/etcd/ssl/node-k8s-1.pem --key=/etc/ssl/etcd/ssl/node-k8s-1-key.pem  get / --keys-only  --prefix
```


## k8s集群合适配置

kubespary 建议 

50节点内:
etcd 和 master 共用 3台机器

50节点以上
etcd 使用3台机器
masster 使用5台机器


