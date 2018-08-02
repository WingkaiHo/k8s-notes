### 添加工作节点

当生产环境工作节点机器负载过高时候需要添加新工作节点。

添加新的工作节点需要修改host.ini 文件

```
[all]
...
node4    ansible_host=10.5.7.14 ip=10.5.7.14 ansible_ssh_user=vagrant ansible_ssh_port=22
node5    ansible_host=10.5.7.15 ip=10.5.7.15 ansible_ssh_user=vagrant ansible_ssh_port=22


[kube-node]
...
node4
node5
```
 
通过脚本修改host.ini文件修改

```
$cd $(kubespray_home)
$CONFIG_FILE=path_to_host_int HOST_PREFIX=host_prefix_name python36 contrib/inventory_builder/inventory.py host-ip
```

如果有删除节点需要删除/tmp/节点名称缓存数据, 修改host.ini以后需要执行命令重新缓存所有节点数据， 否则使用`--limit`参数可能导致失败
```
$ ansible -i inventory/calico-cluster/hosts.ini  all -m setup -b --become-user=root
```

执行添加node操作

scale.yml 脚本会触发docker组件重新启动，会影响其他机器运新, 可以通过`limit`限制只在新添加主机上执行相关命令其他主机不执行，这样可以加快整个安装速度

下面是添加node4,node5主机, 参数以`,`分割，中间不能有空格
```
$ ansible-playbook -b --become-user=root -i inventory/calico-cluster/hosts.ini scale.yml --private-key=~/.vagrant.d/insecure_private_key -l node4,node5
```

通知其他所有主机更新/etc/host
```
ansible-playbook -i inventory/aws_hosts -b cluster.yml --tags etchosts
```

主要解决下面问题
```
$ kubectl logs push-manage-4272813693-nrm7r
Error from server: Get https://node4:10250/containerLogs/prod/push-manage-4272813693-nrm7r/push-manage:  dial tcp: lookup node4 on 10.233.0.2:53: no such host
```
