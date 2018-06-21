## 调度 GPU

### Before you begin

- 1.Kubernetes 节点必须预先安装好 NVIDIA 驱动，否则，Kubelet 将检测不到可用的GPU信息；如果节点的 Capacity 属性中没有出现 NIVIDA GPU 的数量，有可能是驱动没有安装或者安装失败，请尝试重新安装
- 2. 在整个 Kubernetes 系统中，feature-gates 里面特定的 alpha 特性参数 Accelerators 必须设置为 true：--feature-gates="Accelerators=true"
- 3. Kuberntes 节点必须使用 docker 引擎作为容器的运行引擎

### API

容器可以通过名称为 alpha.kubernetes.io/nvidia-gpu 的标识来申请需要使用的 NVIDIA GPU 的数量
```
apiVersion: v1
kind: Pod 
metadata:
  name: gpu-pod
spec: 
  containers: 
    - name: gpu-container-1
      image: k8s.gcr.io/pause:2.0
      resources: 
        limits: 
          alpha.kubernetes.io/nvidia-gpu: 2 # requesting 2 GPUs
    - name: gpu-container-2
      image: k8s.gcr.io/pause:2.0
      resources: 
        limits: 
          alpha.kubernetes.io/nvidia-gpu: 3 # requesting 3 GPUs
```

- GPU 只能在容器资源的 limits 中配置
- 容器和 Pod 都不支持共享 GPU
- 每个容器可以申请使用一个或者多个 GPU
- GPU 必须以整数为单位被申请使用


如果在不同的节点上面安装了不同版本的 GPU，可以通过设置节点标签以及使用节点选择器的方式将 pod 调度到期望运行的节点上。工作流程如下：
在节点上，识别出 GPU 硬件类型，然后将其作为节点标签进行暴露
```
NVIDIA_GPU_NAME=$(nvidia-smi --query-gpu=gpu_name --format=csv,noheader --id=0)
source /etc/default/kubelet
KUBELET_OPTS="$KUBELET_OPTS --node-labels='alpha.kubernetes.io/nvidia-gpu-name=$NVIDIA_GPU_NAME'"
echo "KUBELET_OPTS=$KUBELET_OPTS" > /etc/default/kubelet
```

在 pod 上，通过节点亲和性规则为它指定可以使用的 GPU 类型
```
kind: pod
apiVersion: v1
metadata:
  annotations:
    scheduler.alpha.kubernetes.io/affinity: >
      {
        "nodeAffinity": {
          "requiredDuringSchedulingIgnoredDuringExecution": {
            "nodeSelectorTerms": [
              {
                "matchExpressions": [
                  {
                    "key": "alpha.kubernetes.io/nvidia-gpu-name",
                    "operator": "In",
                    "values": ["Tesla K80", "Tesla P100"]
                  }
                ]
              }
            ]
          }
        }
      }
spec:
  containers:
    -
      name: gpu-container-1
      resources:
        limits:
          alpha.kubernetes.io/nvidia-gpu: 2
```

上述设定可以确保 pod 会被调度到包含名称为 alpha.kubernetes.io/nvidia-gpu-name 的标签并且标签的值为 Tesla K80 或者 Tesla P100 的节点上

所有节点的 GPU 硬件要求相同
