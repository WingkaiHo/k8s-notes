## prometheus-operator 介绍

参考: https://www.kancloud.cn/huyipow/prometheus/529066

我们把这种软件称为 Operator。一个 Operator 指的是一个面向特定应用的控制器，这一控制器对 Kubernetes API 进行了扩展，使用 Kubernetes 用户的行为方式，创建、配置和管理复杂的有状态应用的实例。他构建在基础的 Kubernetes 资源和控制器概念的基础上，但是包含了具体应用领域的运维知识，实现了日常任务的自动化。

Operator 这种软件，使用 TPR(第三方资源，现在已经升级为 CRD) 机制对 Kubernetes API 进行扩展，将特定应用的知识融入其中，让用户可以创建、配置和管理应用。和 Kubernetes 的内置资源一样，Operator 操作的不是一个单实例应用，而是集群范围内的多实例。

prometheus-operator 安装以后可以像创建delpoyment/statefulset 一样通过api控制内置一个或者多个prometheus实例添加/删除监控策略， rules规则。


### prometheus-operator 部署

下载https://gitee.com/huyipow/prometheus-operatorx

目前部署`prometheus-operatorx:v0.22` 版本

参考: prometheus-operator/prometheus-operator/prometheus-operator-cluster-role.yaml
创建prometheus-operator 集群角色
```
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: prometheus-operator
rules:
- apiGroups:
  - apiextensions.k8s.io
  resources:
  - customresourcedefinitions
  verbs:
  - '*'
- apiGroups:
  - monitoring.coreos.com
  resources:
  - alertmanagers
  - prometheuses
  - prometheuses/finalizers
  - alertmanagers/finalizers
  - servicemonitors
  - prometheusrules
  verbs:
  - '*'
- apiGroups:
  - apps
  resources:
  - statefulsets
  verbs:
  - '*'
- apiGroups:
  - ""
  resources:
  - configmaps
  - secrets
  verbs:
  - '*'
- apiGroups:
  - ""
  resources:
  - pods
  verbs:
  - list
  - delete
- apiGroups:
  - ""
  resources:
  - services
  - endpoints
  verbs:
  - get
  - create
  - update
- apiGroups:
  - ""
  resources:
  - nodes
  verbs:
  - list
  - watch
- apiGroups:
  - ""
  resources:
  - namespaces
  verbs:
  - list
  - watch
```
使用旧的导致v0.22版本prometheus-operator无法启动。

创建集群角色用户：prometheus-operator
```
apiVersion: v1
kind: ServiceAccount
metadata:
  name: prometheus-operator
  namespace: monitoring
```

绑定集群角色
cat prometheus-operator-cluster-role-binding.yaml
```
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: prometheus-operator
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: prometheus-operator
subjects:
- kind: ServiceAccount
  name: prometheus-operator
  namespace: monitoring
```

部署prometheus-operator
```
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  labels:
    k8s-app: prometheus-operator
  name: prometheus-operator
  namespace: monitoring
spec:
  replicas: 1
  template:
    metadata:
      labels:
        k8s-app: prometheus-operator
    spec:
      containers:
      - args:
        - --kubelet-service=kube-system/kubelet
        ### 可以根据需求把下载私有仓库添加私有仓库路径
        - --config-reloader-image=quay.io/coreos/configmap-reload:v0.0.1
        ### prometheus default version v2.3.1(operater-statefule接口yaml配置版本)
        - --prometheus-default-base-image=quay.io/prometheus/prometheus
        - --prometheus-config-reloader=quay.io/coreos/prometheus-config-reloader:v0.22.0
        ### 设置thanos-sdecar 镜像地址， 保存prometheus到s3
        - --thanos-default-base-image=improbable/thanos
        image: quay.io/coreos/prometheus-operator:v0.22.0
        name: prometheus-operator
        ports:
        - containerPort: 8080
          name: http
        resources:
          limits:
            cpu: 200m
            memory: 100Mi
          requests:
            cpu: 100m
            memory: 50Mi
      serviceAccountName: prometheus-operator
      securityContext:
        runAsNonRoot: true
        runAsUser: 65534
```

prometheus-operator主要用于接收CRD monitoring.coreos.com/
Prometheus： 在集群上创建一个Prometheus statefulset， 里面内嵌入配置， 接收对应标签ServiceMonitor监控配置。
ServiceMonitor： 控制对应Prometheus添加/删除监控target

prometheus-opeartor service配置:
```
apiVersion: v1
kind: Service
metadata:
  name: prometheus-operator
  namespace: monitoring
  labels:
    k8s-app: prometheus-operator
spec:
  type: ClusterIP
  ports:
  - name: http
    port: 8080
    targetPort: http
    protocol: TCP
  selector:
    k8s-app: prometheus-operator
```

创建prometheus-operator
```
$kubectl create namespace monitoring
$kubectl apply -f ./
```

### 创建监控prometheus-operator 监控target

promethus-k8s-service-monitor-prometheus.yaml
```
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: prometheus-operator
  namespace: monitoring
  labels:
    k8s-app: prometheus-operator
spec:
  endpoints:
  - port: http #获取监控数据port名称，根据prometheus-operator-svt.yaml 设置端口名称
  selector:
    matchLabels:
      k8s-app: prometheus-operator
```

当然需要在promethus-statefule创建以后才生效

```
$kubectl apply -f promethus-k8s-service-monitor-prometheus
```
