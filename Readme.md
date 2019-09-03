# Openvas 10 Docker Image

基于ubuntu18.04 编译安装openvas. 如果需要对应的版本可以自行修改。

## Deployment

**mem > 2G**

If mem < 2g may build error with ccplus.
`cc: fatal error: Killed signal terminated program cc1`

**安装Docker**

安装docker略。

**运行容器**

```bash 
docker run -itd --restart=always \
--name=openvas \
-p 9392:9392 \
-v /srv/docker/openvas/var/run:/usr/local/var/run \
registry.cn-hangzhou.aliyuncs.com/rapid7/openvas:v10
```

## Web 访问接口
```
Username: admin
Password: admin
```

## 监控扫描进程

```
docker top openvas
```

## 查看运行日志
```
docker logs openvas -f 
```


**Update**
```bash 
docker exec -i openvas < ./update_nvt.sh 

```

## 暴露 openvas.sock
```
docker run -itd --restart=always \
--name=openvas \
-p 9392:9392 \
-v /srv/docker/openvas/var/run:/usr/local/var/run \
registry.cn-hangzhou.aliyuncs.com/rapid7/openvas:v10
```
- `docker-compose up -d`

