## 会话保持
此示例演示如何使用cookie实现会话和对应service保持

## 配置绘画保持的ingress

会话粘性是通过在入口3个注解来实现会话保持配置。

|Name|Description|Values|
| --- | --- | --- |
|nginx.ingress.kubernetes.io/affinity|Sets the affinity type|string (in NGINX only ``cookie`` is possible|
|nginx.ingress.kubernetes.io/session-cookie-name|Name of the cookie that will be used|string (default to route)|
|nginx.ingress.kubernetes.io/session-cookie-hash|Type of hash that will be used in cookie value|sha1/md5/index|


### 创建会话保持例子

```
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: app-demo
  annotations:
    nginx.org/websocket-services: "app-websocket"
    annotations:
    nginx.ingress.kubernetes.io/affinity: "cookie"
    nginx.ingress.kubernetes.io/session-cookie-name: "route"
    nginx.ingress.kubernetes.io/session-cookie-hash: "sha1"
spec:
  rules:
  - host: k8s.appdemo.local 
    http:
      paths:
      - path: /
        backend:
          serviceName: app-web
          servicePort: 80
      - path: /api
        backend:
          serviceName: app-service
          servicePort: 8080
      - path: /websocket 
        backend:
          serviceName: app-websocket
          servicePort: 8080
```
   如果后端池增长，NGINX将继续通过第一个请求的同一服务器发送请求，即使它超载。