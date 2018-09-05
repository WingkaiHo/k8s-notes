### k8s 权限分配脚本

   为了安全需要k8s不直接把kube-system admin个开发者/其他管理员。选择每个命名空间都配置管理员帐号这个帐号提高给命名空间管理员. 对应权限有

 - 资源: deployment, ingress, daemonset, statefulset, jod service 等

 - 动作: 列举，创建，删除，更新，exec（运行容器控制台）

 - 限制: 只限制对应命名空间，集群信息/集群资源(pv，节点)不能查看

### 创建对应命名空间管理帐号

1. 脚本负责创建和配置对应命名空间管理员rabc权限
2. 下载k8s对应ca证书， 管理员token到当前目录下对应命名空间目录

创建帐号和生成命名空间配置文件:
```
$ ./create-namepspace-admin-role.sh gitlab-cd-demo 172.25.52.216:6443
$ ls
create-namepspace-admin-role.sh  gitlab-cd-demo  rabc-tmpl.yaml  README.md  set_kubectl_context-tmpl.sh
```

目录gitlab-cd-demo命名空间需要配置文件，打包发送给下级管理员，管理员就可以控制这个命令空间。

3. 管理员操作gitlab-cd-demo， 需要对应机器上kubectl工具
```
$ ls gitlab-cd-demo/
admin-gitlab-cd-demo-rabc.yaml  ca.crt  set_kubectl_context.sh  token
$ cd gitlab-cd-demo/
$ ./set_kubectl_context.sh
$ kubectl get pod
```
