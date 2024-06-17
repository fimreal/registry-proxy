## Registry Proxy

#### Description
This is a proxy for the Docker Registry. It is used to cache the Docker images in a local registry. It is also used to proxy the requests to the Docker registry.


#### Usage

You can open the Caddyfile to configure your proxy domain, and Caddy will help you resolve the certificate issue, or you can refer to the [link](https://caddyserver.com/docs/running#local-https-with-docker) to view the method of using a self-signed certificate.

You can open the [.env](/docker-compose/.env) file to edit your proxy settings, which are used to access the source address within restricted networks.

quick-start:

```bash
# start service
docker compose up -d
# kill
docker compose down
```
