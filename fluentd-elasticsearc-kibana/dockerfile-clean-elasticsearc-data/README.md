### 制作镜像
编辑build-image.sh,镜像相关信息， 只需要修改HARBOR_ADDR就可以了
 
```
HARBOR_ADDR=192.168.0.1
PROJECT=library
IMAGE_NAME=crontab-cleanup-ela-data
VERSON=1.0
```

执行制作镜像脚步， 机器需要安装docker
```
$build-image.sh
```

### 推送镜像到仓库
```
$docker push <HARBOR_ADDR>/library/crontab-cleanup-ela-data:1.0
按指示输入密码
```
