### 1.通过ingress整合多服务的平台

例如有平台有3服务，一个服务`app_web`前端， 一个服务是后台`app_service`, 一个websocker服务是`app_websocket`

- app_web
  处理web前端的服务
- app_service 
  处理/api/请求类型的服务
- app_websocker
  处理/websocket/请求类型的服务

  处理host名称k8s.appdemo.local, yaml 如下：
```
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: app-demo
  annotations:
    nginx.org/websocket-services: "app-websocket"
spec:
  rules:
  - host: k8s.appdemo.local 
    http:
      paths:
      - path: /
        backend:
          serviceName: app-web
          servicePort: 80
      - path: /api/ 
        backend:
          serviceName: app-service
          servicePort: 8080
      - path: /websocket 
        backend:
          serviceName: app-websocket
          servicePort: 8080
```
