# docker-nginx-letsencrypt-proxy

This [repository](https://github.com/Paldom/docker-nginx-letsencrypt-proxy) contains the Dockerfile of the [dpal/docker-nginx-letsencrypt-proxy](https://hub.docker.com/r/dpal/docker-nginx-letsencrypt-proxy/) image. 

Quick &amp; easy HTTPS reverse proxy for your Docker services. Publish each of your Docker services and secure them with SSL certificates.

Let's assume you have a multi-container Docker application system, that consists of an api, a website, and admin interfaces for database and for content management. You may have the following network by default in your `docker-compose.yml`:

- api:3000
- dbadmin:9000
- web:80
- webadmin:8080

With this [dpal/docker-nginx-letsencrypt-proxy](https://hub.docker.com/r/dpal/docker-nginx-letsencrypt-proxy/) image you can easly set up an NGINX reverse proxy and generate SSL certificates with certbot for your domains or subdomains, so that you can access these virtual hosts via a secure HTTPS connection. For example with yourdomain.com:

| ADDRESS       | VIRTUAL HOST                    |
|---------------|---------------------------------|
| api:3000      | https://api.yourdomain.com      |
| dbadmin:9000  | https://dbadmin.yourdomain.com  |
| web:80        | https://web.yourdomain.com      |
| webadmin:8080 | https://webadmin.yourdomain.com |

## Usage

### Requirements

Before running a docker image, please ensure:

* You have a domain registered
* DNS is configured properly (e.g. "A" records are set to your public IP)
* Your host machine is available from the internet

### Params

You can use the following environment variables:

* **EMAIL** - Your email address for certbot (Let's encrypt)
* **SERVICE_HOST_1** - Public virtual host e.g. `api.yourdomain.com`
* **SERVICE_ADDRESS_1** - Internal address of Docker service e.g. `api`
* **SERVICE_PORT_1** - Internal port of your Docker service e.g. `3000`
...
You can define as many service you want:
* **SERVICE_HOST_N** - Nth host
* **SERVICE_ADDRESS_N** - Nth internal address
* **SERVICE_PORT_N** - Nth internal port

### Examples

#### 1. Proxy services from a docker network
Here's a simple `docker-compose.yml` to try this image with your domain. `service1` and `service2` are dummy hosts running in docker network. 

```yaml

version: '3.4'
services:

  nginx: 
    image: dpal/docker-nginx-letsencrypt-proxy:latest
    container_name: nginx
    environment:
      - EMAIL=public@dpal.hu
      - SERVICE_HOST_1=api1.yourdomain.com
      - SERVICE_ADDRESS_1=service1
      - SERVICE_PORT_1=3001
      - SERVICE_HOST_2=api2.yourdomain.com
      - SERVICE_ADDRESS_2=service2
      - SERVICE_PORT_2=3002
    volumes:
      - ./data/nginx/error.log:/etc/nginx/error_log.log
      - ./data/nginx/cache/:/etc/nginx/cache
    ports:
      - 80:80
      - 443:443
    expose:
      - "80"
      - "443"
    networks:
      - api-network

  service1: 
    image: node:alpine
    container_name: service1
    ports:
      - 3001:3001
    command:  >
      sh -c "echo 'var h=require(\"http\"),s=h.createServer(function(e,r){r.writeHead(200),r.end(\"api1\")});s.listen(3001);' > index.js && 
             node index.js"
    networks:
      - api-network 

  service2: 
    image: node:alpine
    container_name: service2
    ports:
      - 3002:3002
    command:  >
      sh -c "echo 'var h=require(\"http\"),s=h.createServer(function(e,r){r.writeHead(200),r.end(\"api2\")});s.listen(3002);' > index.js && 
             node index.js"
    networks:
      - api-network 


networks:
  api-network:
    driver: bridge


```

#### 2. Proxy services from a host network
`docker-compose.yml` to serve `localhost:3001` and `localhost:3002` services from your host network.

```yaml

version: '3.4'
services:

  nginx: 
    image: dpal/docker-nginx-letsencrypt-proxy:latest
    container_name: nginx
    environment:
      - EMAIL=public@dpal.hu
      - SERVICE_HOST_1=api1.yourdomain.com
      - SERVICE_ADDRESS_1=localhost
      - SERVICE_PORT_1=3001
      - SERVICE_HOST_2=api2.yourdomain.com
      - SERVICE_ADDRESS_2=localhost
      - SERVICE_PORT_2=3002
    volumes:
      - ./data/nginx/error.log:/etc/nginx/error_log.log
      - ./data/nginx/cache/:/etc/nginx/cache
    expose:
      - "80"
      - "443"
    network_mode: host

```

#### 3. Proxy services from a host network with docker run

Pull image from Docker Hub:

```sh
docker pull dpal/docker-nginx-letsencrypt-proxy:latest
```

Or build from GitHub:

```sh
docker build -t dpal/docker-nginx-letsencrypt-proxy github.com/paldom/docker-nginx-letsencrypt-proxy
```

Run image with `docker run` instead of `docker-compose`:

```sh
docker run -d --network host --expose=80 --expose=443 \
  -e EMAIL=public@dpal.hu \
  -e SERVICE_HOST_1=api1.yourdomain.com \
  -e SERVICE_ADDRESS_1=localhost \
  -e SERVICE_PORT_1=3001 \
  -e SERVICE_HOST_2=api2.yourdomain.com \
  -e SERVICE_ADDRESS_2=localhost \
  -e SERVICE_PORT_2=3002 \
  dpal/docker-nginx-letsencrypt-proxy:latest
```

## NGINX

Currently the following nginx configuration is used by default for each virtual host. Some parts are managed by certbot automatically.

```conf

server {
    server_name example.com;
    location / {
        proxy_pass "http://0.0.0.0:0000";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Upgrade $http_upgrade;
        proxy_cache_bypass $http_upgrade;
        proxy_http_version 1.1;
        proxy_set_header Connection keep-alive;
        proxy_redirect off;
    }
    if ($scheme != "https") {
        return 301 https://$host$request_uri;
    }
    listen 80;
    listen 443 ssl; # managed by Certbot
    ssl_certificate /etc/letsencrypt/live/example.com/fullchain.pem; # managed by Certbot
    ssl_certificate_key /etc/letsencrypt/live/example.com/privkey.pem; # managed by Certbot
    include /etc/letsencrypt/options-ssl-nginx.conf; # managed by Certbot
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem; # managed by Certbot
}


```
