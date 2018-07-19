## prometheus 安装

### 创建prometheus对应保存数据local-pv.yml ,如果有两个实例需要配置两个pv
```
apiVersion: v1
kind: PersistentVolume
metadata:
  name: prometheus
  labels:
     app: prometheus   
  annotations:
    volume.alpha.kubernetes.io/node-affinity: |
      {
         "requiredDuringSchedulingIgnoredDuringExecution": {
           "nodeSelectorTerms": [
            { "matchExpressions": [
               { "key": "kubernetes.io/hostname",
                 "operator": "In",
                 # 可以指定pv机器， 如果不指定实例飘移到其他机器导致丢失数据
                 "values": ["node3"]
               }
           ]}
         ]}
      }
spec:
  capacity:
    storage: 20Gi
  accessModes:
  - ReadWriteOnce
  storageClassName: local-storage
  hostPath:
    path: /var/lib/docker/prometheus
```

### 创建prometheus-k8s 角色账号
```
apiVersion: v1
kind: ServiceAccount
metadata:
  name: prometheus-k8s
  namespace: monitoring
```


### kube-system 和 monitoring 空间，创建 prometheus-k8s 角色用户权限 
```
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: Role
metadata:
  name: prometheus-k8s
  namespace: monitoring
rules:
- apiGroups: [""]
  resources:
  - nodes
  - services
  - endpoints
  - pods
  verbs: ["get", "list", "watch"]
- apiGroups: [""]
  resources:
  - configmaps
  verbs: ["get"]
---
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: Role
metadata:
  name: prometheus-k8s
  namespace: kube-system
rules:
- apiGroups: [""]
  resources:
  - services
  - endpoints
  - pods
  verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: Role
metadata:
  name: prometheus-k8s
  namespace: default
rules:
- apiGroups: [""]
  resources:
  - services
  - endpoints
  - pods
  verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRole
metadata:
  name: prometheus-k8s
rules:
- nonResourceURLs: ["/metrics"]
  verbs: ["get"]
```

### 绑定用户Role

```
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: RoleBinding
metadata:
  name: prometheus-k8s
  namespace: default
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: prometheus-k8s
subjects:
- kind: ServiceAccount
  name: prometheus-k8s
  namespace: monitoring
---
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: RoleBinding
metadata:
  name: prometheus-k8s
  namespace: kube-system
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: prometheus-k8s
subjects:
- kind: ServiceAccount
  name: prometheus-k8s
  namespace: monitoring
---
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: RoleBinding
metadata:
  name: prometheus-k8s
  namespace: monitoring
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: prometheus-k8s
subjects:
- kind: ServiceAccount
  name: prometheus-k8s
  namespace: monitoring
---
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: prometheus-k8s
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: prometheus-k8s
subjects:
- kind: ServiceAccount
  name: prometheus-k8s
  namespace: monitoring
```

### statefulset 方式部署prometheus
prometheus 是通过prometheus-operator接口创建的statefulset， 由k8s进行管理

```
apiVersion: monitoring.coreos.com/v1
kind: Prometheus
metadata:
  name: k8s
  namespace: monitoring
  labels:
    prometheus: k8s
spec:
  replicas: 1
  version: v2.3.1
  retention: 24h  # Prometheus 时序数据保存时间（24小时， 一天以后数据就被清空, 保存7天retention: 7d)
  serviceAccountName: prometheus-k8s
  serviceMonitorSelector:
    # 下面意思这个Prometheus statefule 所有实例遇到有k8s-app标签的ServiceMonitor都接收更新Prometheus监控
    # 任务
    matchExpressions:
    - {key: k8s-app, operator: Exists}
  ruleSelector:
    matchLabels:
      role: prometheus-rulefiles
      prometheus: k8s
  resources:
    requests:
      memory: 1G
  securityContext:
    ## 保存文件的时候没有root无法写入文件
    runAsUser: 0
  storage:
    volumeClaimTemplate:
      metadata:
        name: prometheus-data
      spec:
        accessModes: [ "ReadWriteOnce" ]
        resources:
          requests:
            storage: 20Gi
        storageClassName: local-storage
        selector:
          matchLabels:
            # 绑定对应prometheus pv
            app: prometheus
  alerting:
    alertmanagers:
    - namespace: monitoring
      name: alertmanager-main
      port: web
  podMetadata:
    labels:
      thanos-peer: 'true'
  thanos:
    # 通过thanos 把prometheus数据保存到s3， 通过thanos-querier接口代替Prometheus查询多个实例/retention 外历史监控数据
    peers: thanos-peers.monitoring.svc:10900   
    version: v0.1.0-rc.2 
```

### thanos-query 安装

查询组件实现Prometheus HTTP v1 API，以通过PromQL查询Thanos集群中的数据， Thanos集群包含一个或者多个不同任务Prometheus实例，通过他可以查询thanos-sidecar保存在s3存储更久历史的监控数据

```
apiVersion: apps/v1
kind: Deployment
metadata:
  namespace: monitoring
  name: thanos-query
  labels:
    app: thanos-query
    thanos-peer: "true"
spec:
  replicas: 1
  selector:
    matchLabels:
      app: thanos-query
      thanos-peer: "true"
  template:
    metadata:
      labels:
        app: thanos-query
        thanos-peer: "true"
    spec:
      containers:
      - name: thanos-query
        image: improbable/thanos:v0.1.0-rc.2
        args:
        - "query"
        - "--log.level=debug"
        - "--query.replica-label=prometheus_replica"
        - "--cluster.peers=thanos-peers.monitoring.svc:10900"
        ports:
        - name: http
          containerPort: 10902
        - name: grpc
          containerPort: 10901
        - name: cluster
          containerPort: 10900
```

配置thanos-query需要服务

thanos-peers-svc.yaml， 提供给thanos-sidecar 进行连接
```
apiVersion: v1
kind: Service
metadata:
  namespace: monitoring
  name: thanos-peers
spec:
  type: ClusterIP
  clusterIP: None
  ports:
  - name: cluster
    port: 10900
    targetPort: cluster
  selector:
    thanos-peer: "true"
```

下面这个服务提供查询使用
```
apiVersion: v1
kind: Service
metadata:
  namespace: monitoring
  labels:
    app: thanos-query
  name: thanos-query
spec:
  selector:
    app: thanos-query
  type: NodePort
  ports:
  - port: 9090
    protocol: TCP
    targetPort: http
    nodePort: 30901
    name: http-query
```
查询端口界面和prometheus基本一致。


