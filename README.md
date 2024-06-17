## registry-proxy

#### Overview
容器镜像仓库代理配置归档，方便一次性启动

#### Usage

git clone

```bash
git clone https://github.com/fimreal/registry-proxy.git
```

(1) docker run

```bash
bash ./cli/docker_run.sh
```

(2) docker-compose

```bash
cd docker_compose
docker-compose up -d
```

(3) k8s

```bash
kubectl apply -f k8s/
```

#### 其他
[网页交互式申请 ssl 证书](https://epurs.com/i/acme.html)
