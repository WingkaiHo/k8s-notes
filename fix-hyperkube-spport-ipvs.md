### hyperkube 漏安装ipset 导致不能使用ipvs mode

在v1.9.5基础上安装ipset软件包

编写dockerfile如下：
```
FROM gcr.io/google-containers/hyperkube:v1.9.5

RUN apt-get update && apt-get install -y --no-install-recommends \
		ipset \
	&& rm -rf /var/lib/apt/lists/*
```

重新build镜像并且存放私有仓库中
