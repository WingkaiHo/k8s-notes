### 部署ingress-controller backend
当ingress controller 没有匹配对应host/域名时候， 显示不存在页面

编写 default-backend.yaml
```
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: default-http-backend
  labels:
    app: default-http-backend
  namespace: kube-system
spec:
  replicas: 1
  selector:
    matchLabels:
      app: default-http-backend
  template:
    metadata:
      labels:
        app: default-http-backend
    spec:
      terminationGracePeriodSeconds: 60
      containers:
      - name: default-http-backend
        # Any image is permissible as long as:
        # 1. It serves a 404 page at /
        # 2. It serves 200 on a /healthz endpoint
        image: gcr.io/google_containers/defaultbackend:1.4
        livenessProbe:
          httpGet:
            path: /healthz
            port: 8080
            scheme: HTTP
          initialDelaySeconds: 30
          timeoutSeconds: 5
        ports:
        - containerPort: 8080
        resources:
          limits:
            cpu: 10m
            memory: 20Mi
          requests:
            cpu: 10m
            memory: 20Mi
---

apiVersion: v1
kind: Service
metadata:
  name: default-http-backend
  namespace: kube-system
  labels:
    app: default-http-backend
spec:
  ports:
  - port: 80
    targetPort: 8080
  selector:
    app: default-http-backend

```
执行下面命令创建
```
$kubectl apply -f default-backend.yaml
```

### 部署ingress 配置表（configmap）
配置ingress-controller-configmap.yaml 
```
kind: ConfigMap
apiVersion: v1
metadata:
  name: nginx-configuration
  namespace: kube-system
  labels:
    app: ingress-nginx
data:
  #配置用户最大上传数据大小
  proxy-body-size: "3000m"
  # 配置websocket 支持
  proxy-read-timeout "3600"
  proxy-write-timeout "3600"
```
执行下面命令：
```
$kubectl apply -f ingress-controller-configmap.yaml
```
### 部署ingress-congrller
启动ingresscontroller需要在创建配置表以后
```

```


