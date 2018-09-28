### 背景

   默认的情况，在K8S里启动一个容器，该容器的设置的时区是UTC0，但是对于很多客户而言，其主机环境并不在UTC0。例如中国客户在UTC8。如果不把容器的时区和主机主机设置为一致，则在查找日志等时候将非常不方便，也容易造成误解.

### Kubernetes的时区设置方式

通过环境变量:
```
apiVersion: v1
kind: Pod
metadata:
  name: pod-env-tz
spec:
  containers:
  - name: ngx
    image: nginx:latest
    imagePullPolicy: IfNotPresent
    env:
      - name: TZ
        value: Asia/Shanghai
```

通过挂载主机时区文件设置
```
apiVersion: v1
kind: Pod
metadata:
  name: pod-vol-tz
spec:
  containers:
  - name: ngx
    image: nginx:latest
    imagePullPolicy: IfNotPresent
    volumeMounts:
    - name: tz-config
      mountPath: /etc/localtime
      readOnly: true
  volumes:
  - name: tz-config
    hostPath:
      path: /etc/localtime
```

### 通过Pod Preset预设置时区环境变量

   如果每次需要手动编写比较麻烦， 能否通过系统自动注入， 而无需在对应yaml文件体现。答案是使用K8S的特性Pod Preset来控制容器启动前先配置好对应时区环境变量，或者挂载主机文件。

**底层准备**

apiserver 需要添加下面两个配置:
```
--runtime-config=settings.k8s.io/v1alpha1=true
--enable-admission-plugins=PodPreset
```

对应的Pod Preset对象创建文件如下 tz-podpreset.yaml：
```
apiVersion: settings.k8s.io/v1alpha1
kind: PodPreset
metadata:
  name: allow-tz-env
spec:
  selector:
    matchLabels:
  env:
    - name: TZ
      value: Asia/Shanghai
```

执行命令创建
```
$kubectl apply -f tz-podpreset.yaml -n default
```

tz-podpreset 只在对应的namespace上有效果，需要在多个命名空间上创建。

然后可用以普通方式启动pod/depleoyment， 时区代码自动注入例如:

```
apiVersion: v1
kind: Pod
metadata:
  name: pod-no-tz
spec:
  containers:
  - name: ngx
    image: nginx:latest
    imagePullPolicy: IfNotPresent
```

### 总结
   至此，我们就完成了容器的时区的"自动"配置了. 需要注意的是，Pod Preset是namespace级别的对象，其作用范围只能是同一个命名空间下容器。
