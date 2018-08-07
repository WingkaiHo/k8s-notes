### Kubernetes master 高可用
  
  kubernetes master 高可用基于etcd集群高可用上面做的。

### kubernetes 做高可用原因

  master需要配置为高可用ha集群， master保证有一个以上kube-apiserver是活动的， node节点`kubelet`如果不能连接上kube-apiserver更新状态, 导致kube-controller-manger触发pod_eviction_timeout, 超过pod_eviction_timeout检测不到来自node的心跳，就会认为这个node已经挂掉，当mater组件重新启动的时候然后就会把该node上的pod全部删除. 如果`kube-apiserver`所有实例都down， 引起kube-controller-manager认为所有节点都有问题。

![ha](img/loadbalancer_localhost.png)

- kube-master: kube-controller-manager, kube-schedule-server, kubelet， kubectl, 都是通过localhost:6443/localhost:8080 和kube-apiserver进行通信。kubespray 部署要求kube-master 组有2～5台master。

- kube-node: 节点都是通过nginx-proxy容器进行方向代理去访问apiserver，同样kubelet, kube-proxy等组件都是通过localhost:6443和kube-apiserver进行通信， nginx配置如下:
```
error_log stderr notice;

worker_processes auto;
events {
  multi_accept on;
  use epoll;
  worker_connections 1024;
}

stream {
        upstream kube_apiserver {
            least_conn;
            server 10.4.6.11:6443;
            server 10.4.6.12:6443;
            server 10.4.6.14:6443;
                    }

        server {
            listen        127.0.0.1:6443;
            proxy_pass    kube_apiserver;
            proxy_timeout 10m;
            proxy_connect_timeout 1s;

        }

}
```

上面把localhost:6443 转发到 10.4.6.11:6443/10.4.6.12:6443/10.4.6.14:6443， 如果apiserver节点拿台有问题，自动进行切换。

### master 升级/添加需要

  master 更新时候需要保持集群有一个以上. 添加master也需要通过`upgrade-cluster.yaml`进行添加， 和`cluster.yaml`区别是使用` serial: "{{ serial | default('20%') }}"` 实现按照master节点数目20%滚动更新， 保证master机器分开重新启动和更新参数（防止master同时更新导致无法工作）， master节点需要更新apicount等参数，以及cert， token等文件。脚本命令如下：

```
$ ansible-playbook -i inventory/cilumn-cluster/hosts.ini  -b --become-user=root --private-key=path_to_insecure_private_key upgrade-cluster.yml --tags=master
```

   通知所有节点更新/etc/hosts
```
ansible-playbook -i inventory/cilumn-cluster/hosts.ini  -b --become-user=root --private-key=path_to_insecure_private_key upgrade-cluster.yml --tags=etchosts
```

   通知所有Node更新nginx proxy config 以及执行nginx 容器执行reload configure 

修改kubespray roles/kubernetes/node/tasks/nginx-proxy.yml 文件添加reload configure代码
```
- name: Nginx proxy reload config 
  shell:  docker ps -af name=k8s_nginx-proxy_nginx-proxy-{{inventory_hostname}} -q | awk '{print  $1 " nginx -s reload"}' | xargs --no-run-if-empty docker exec
```

执行ansible脚本如下:
```
$ ansible-playbook -i inventory/cilumn-cluster/hosts.ini  -b --become-user=root --private-key=path_to_insecure_private_key upgrade-cluster.yml --tags=nginx
```
docker ps -af name=k8s_nginx-proxy* -q | awk '{print  $1 " nginx -s reload"}' | xargs --no-run-if-empty docker exec
