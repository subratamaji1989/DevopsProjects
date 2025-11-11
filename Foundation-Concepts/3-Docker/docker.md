# Docker Cheat Sheet (Beginner → Expert)

> One-page (and beyond) practical reference covering installation, core concepts, commands, recipes, best practices, advanced use, debugging, and security.

---

## Table of Contents

1. Introduction & Installation
2. Docker CLI Basics
3. Working with Images
4. Containers
5. Volumes
6. Docker Networking
7. Dockerfiles
8. Docker Compose
9. Docker Swarm
10. Docker Buildx and Advanced Builds
11. Best Practices
12. Advanced Usage & Debugging
13. Security Tips
14. Useful Commands Summary

---

# 1. Introduction & Installation

**What is Docker?**

* Container runtime that packages applications and dependencies into lightweight, portable units.
* Key idea: build once, run anywhere.

**Core components**

* Image: immutable template (read-only) for creating containers.
* Container: running instance of an image.
* Dockerfile: recipe to build images.
* Docker Engine (daemon) and CLI.

**Install (high-level)**

* macOS: Docker Desktop (recommended).
* Windows: Docker Desktop (WSL2 backend recommended).
* Linux: install `docker-ce` via package manager (Debian/Ubuntu `apt`, RHEL/CentOS `yum`/`dnf`).

Quick check after install:

```bash
docker version    # client + server
docker info       # daemon info
```

---

# 2. Docker CLI Basics

**Common flags**

* `-d` or `--detach`: run container in background
* `-it`: interactive TTY (`-i` + `-t`)
* `--rm`: remove container when it exits
* `-p HOST:CONTAINER`: port mapping
* `-v HOST:CONTAINER` or `--mount`: attach storage
* `--name NAME`: name the container

**Basic workflow**

* Pull: `docker pull IMAGE[:TAG]`
* Run: `docker run [OPTIONS] IMAGE [COMMAND] [ARGS]`
* List: `docker ps` (running), `docker ps -a` (all)
* Stop: `docker stop CONTAINER`
* Remove: `docker rm CONTAINER`
* Logs: `docker logs CONTAINER`

Examples:

```bash
docker run --name web -d -p 8080:80 nginx:latest
docker run -it --rm ubuntu:22.04 bash
```

---

# 3. Working with Images

**Image lifecycle**

* Build (`docker build`) → Tag → Push (`docker push`) → Pull

**Build**

```bash
# From current directory with Dockerfile
docker build -t myapp:1.0 .
# Specify Dockerfile name
docker build -f Dockerfile.prod -t myapp:1.0 .
```

**Tag & push**

```bash
docker tag myapp:1.0 myrepo/myapp:1.0
docker push myrepo/myapp:1.0
```

**Inspecting images**

* `docker images` list
* `docker image inspect IMAGE` — JSON metadata
* `docker history IMAGE` — image layer history

**Saving & loading**

```bash
docker save -o myapp.tar myapp:1.0
docker load -i myapp.tar
```

**Best image-related tips**

* Prefer small base images (e.g., `alpine`, `distroless`) when appropriate.
* Use multi-stage builds to reduce final image size.
* Pin tags for reproducibility (`node:18.16.0` vs `node:latest`).

---

# 4. Containers

**Run differences**

* Interactive shell: `docker run -it --rm image bash`
* Daemonized: `docker run -d image`

**Manage lifecycle**

```bash
docker ps -a
docker stop CONTAINER
docker start CONTAINER
docker restart CONTAINER
docker exec -it CONTAINER bash      # run command in running container
docker attach CONTAINER             # attach to main process (caresful)
```

**Inspect & stats**

* `docker inspect CONTAINER` — JSON with config, mounts, networks
* `docker logs CONTAINER` — container stdout/stderr
* `docker stats CONTAINER` — live resource usage

**Common pitfalls**

* Processes must run PID 1 in container (use tini/init or `--init`).
* Exited containers still consume disk space (remove with `docker rm`).
* Orphaned volumes: remove with `docker volume prune`.

---

# 5. Volumes

**Types**

* Bind mount: host path → container (`-v /host/path:/container/path`)
* Named volume: managed by Docker (`-v myvol:/data`)
* tmpfs: in-memory filesystem (`--tmpfs /data`)

**Create & manage**

```bash
docker volume create mydata
docker run -v mydata:/var/lib/mysql mysql
docker volume ls
docker volume inspect mydata
docker volume rm mydata
```

**When to use what**

* Development: use bind mounts for live code editing.
* Production: use named volumes or external storage drivers (NFS, cloud volumes).

**Backup & restore**

```bash
# Backup named volume
docker run --rm -v mydata:/data -v $(pwd):/backup alpine \
  tar czf /backup/mydata.tgz -C /data .
# Restore
docker run --rm -v mydata:/data -v $(pwd):/backup alpine \
  sh -c "tar xzf /backup/mydata.tgz -C /data"
```

---

# 6. Docker Networking

**Default networks**

* `bridge` (default for standalone containers)
* `host` (container shares host network namespace)
* `none` (no networking)

**Manage networks**

```bash
docker network ls
docker network inspect bridge
docker network create --driver bridge mynet
docker run --network mynet --name app ...
```

**Communication**

* Containers on same user-defined bridge network can reach each other by name (DNS-based).
* Use `--network host` for low-latency or special networking (Linux only).

**Port mapping**

* `-p HOST_PORT:CONTAINER_PORT` exposes container port to host.
* `-P` publishes all exposed ports on random host ports.

**Advanced**

* Use overlay networks with Swarm/Kubernetes for multi-host networking.
* Macvlan for exposing containers as first-class devices on LAN.

---

# 7. Dockerfiles

**Essential structure**

```Dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --production
COPY . .
CMD ["node","server.js"]
```

**Key instructions**

* `FROM`, `COPY`, `ADD`, `RUN`, `CMD`, `ENTRYPOINT`, `ENV`, `EXPOSE`, `WORKDIR`, `USER`, `VOLUME`

**ENTRYPOINT vs CMD**

* `ENTRYPOINT` sets the executable; `CMD` provides default args. `ENTRYPOINT` + `CMD` forms a default command with arguments.

**Multistage builds**

```Dockerfile
# build stage
FROM golang:1.21 AS builder
WORKDIR /src
COPY . .
RUN CGO_ENABLED=0 go build -o /out/myapp ./...

# final stage
FROM gcr.io/distroless/cc
COPY --from=builder /out/myapp /usr/local/bin/myapp
ENTRYPOINT ["/usr/local/bin/myapp"]
```

**Build cache tips**

* Order layers so that infrequently-changing steps (like `RUN apt-get update && apt-get install`) come early.
* Use `.dockerignore` to exclude large/unnecessary files.

---

# 8. Docker Compose

**Purpose**: Define multi-container apps with a YAML file.

**Basic `docker-compose.yml`**

```yaml
version: '3.8'
services:
  web:
    build: ./web
    ports:
      - "8080:80"
    depends_on:
      - db
  db:
    image: postgres:15
    volumes:
      - dbdata:/var/lib/postgresql/data
volumes:
  dbdata:
```

**Common commands**

```bash
docker compose up         # foreground
docker compose up -d      # detached
docker compose down       # stop & remove resources
docker compose logs -f    # stream logs
docker compose ps         # list services
```

**Overrides & profiles**

* `docker compose -f docker-compose.yml -f docker-compose.prod.yml up` for overrides.
* Profiles allow optional services: `profiles: ["dev"]`.

---

# 9. Docker Swarm

**Purpose**: Native Docker orchestration for clustering and scaling containers.

**Initialize Swarm**

```bash
docker swarm init                    # on manager node
docker swarm join-token worker       # get token for workers
docker swarm join-token manager      # get token for managers
```

**Deploy services**

```bash
docker service create --name web -p 80:80 --replicas 3 nginx
docker service ls
docker service ps web                # see tasks
docker service scale web=5           # scale to 5 replicas
docker service update --image nginx:alpine web  # rolling update
```

**Manage Swarm**

```bash
docker node ls                       # list nodes
docker service logs web              # service logs
docker service rm web                # remove service
docker swarm leave                   # leave swarm (force with --force)
```

**Secrets and configs**

```bash
echo "secret" | docker secret create mysecret -
docker service create --secret mysecret webapp
```

**Stacks with Compose**

```bash
docker stack deploy -c docker-compose.yml mystack
docker stack ls
docker stack services mystack
docker stack rm mystack
```

---

# 10. Docker Buildx and Advanced Builds

**Buildx**: Advanced builder for multi-platform, efficient builds.

**Enable Buildx**

```bash
docker buildx create --use --name mybuilder  # create and use builder
docker buildx ls                             # list builders
```

**Multi-platform builds**

```bash
docker buildx build --platform linux/amd64,linux/arm64 -t myapp:multi .
# Push to registry
docker buildx build --push --platform linux/amd64,linux/arm64 -t myrepo/myapp:multi .
```

**Build secrets**

```bash
# Pass secrets without baking into image
docker buildx build --secret id=github_token,env=GITHUB_TOKEN -t myapp .
# In Dockerfile: RUN --mount=type=secret,id=github_token,target=/run/secrets/github_token
```

**Advanced features**

* **Bake**: Build multiple images from a single file.
* **Cache**: Export/import build cache for faster rebuilds.
* **Attestations**: Add SBOMs and provenance.

**Docker Scout**: Vulnerability scanning.

```bash
docker scout cves myimage:latest     # scan for CVEs
docker scout recommendations myimage # get recommendations
docker scout compare myimage:v1 myimage:v2  # compare versions
```

---

# 11. Best Practices

**Images & builds**

* Pin base image tags. Use minimal base images.
* Use multi-stage builds to minimize final image size.
* Keep Dockerfiles readable and cache-friendly.
* Use `.dockerignore`.

**Containers**

* Run as non-root user when possible. `USER` in Dockerfile.
* Limit resources: `--memory`, `--cpus`.
* Use healthchecks: `HEALTHCHECK` in Dockerfile or `healthcheck` in compose.

**CI/CD**

* Rebuild only what's necessary; cache layers wisely.
* Scan images for vulnerabilities during pipeline.

**Configuration & secrets**

* Do *not* bake secrets into images. Use environment variables, secrets managers, or Docker secrets for Swarm/Kubernetes.

**Logging & monitoring**

* Send logs to centralized logging (e.g., fluentd, ELK). Use `docker logs` for debugging.
* Expose metrics and use monitoring (Prometheus, cAdvisor).

---

# 12. Advanced Usage & Debugging

**Attach a shell to a running container**

```bash
docker exec -it CONTAINER /bin/bash || /bin/sh
```

**Debugging tips**

* `docker inspect` gives config, mounts, networks, envs.
* `docker logs --since 1h CONTAINER` limit logs by time.
* `docker commit` to snapshot a container for debugging (not for production images).
* Use `strace`/`lsof` inside container (install temporarily) to debug low-level issues.

**Performance & tuning**

* On Linux, use native Docker; on macOS/Windows, file sharing can be slow (use `cached`/`delegated` options for bind mounts on Docker Desktop where supported).
* Reduce image size and number of layers.

**Garbage collection**

```bash
docker system df                # disk usage
docker system prune             # remove unused data (images, containers, networks)
docker system prune -a          # remove unused images too
```

Be careful: `-a` will remove images not referenced by any container.

**Using Docker with Kubernetes**

* Docker images are the packaging format for many Kubernetes workloads.
* For local testing, use `kind`, `minikube`, or `k3s`.

**Debugging network issues**

* `docker network inspect` to see endpoints.
* `docker run --network container:OTHER_CONTAINER --rm busybox nslookup service` for DNS tests.

---

# 13. Security Tips

**Least privilege**

* Run processes as non-root user. `USER nobody` or custom user.
* Use `--cap-drop` and `--cap-add` to control capabilities.

**Images**

* Scan images with tools like Trivy, Clair, or Docker Scout.
* Prefer signed images (Notary / Docker Content Trust).

**Runtime**

* Use seccomp, AppArmor, SELinux profiles where supported.
* Limit resources and use read-only file systems when possible: `--read-only` and writable temp dirs.

**Secrets**

* Use secret stores (Vault, AWS Secrets Manager, Docker Secrets for Swarm) — do not pass secrets on the CLI.

**Network isolation**

* Use user-defined networks and firewall rules. Avoid exposing ports unnecessarily.

---

# 14. Useful Commands Summary

**Images**

```bash
docker images
docker pull IMAGE
docker build -t name:tag .
docker push repo/name:tag
docker rmi IMAGE
docker image prune -a
```

**Containers**

```bash
docker ps -a
docker run -d --name name -p 80:80 image
docker stop name
docker start name
docker rm name
docker logs -f name
docker exec -it name bash
```

**Volumes & Networks**

```bash
docker volume ls
docker volume create v
docker volume rm v

docker network ls
docker network create mynet
```

**System**

```bash
docker system df
docker system prune
docker system prune -a
```

**Compose**

```bash
docker compose up -d
docker compose logs -f
docker compose down --volumes
```

---

# Quick Reference: One-liners

* Remove all stopped containers:

```bash
docker container prune
```

* Remove dangling images:

```bash
docker image prune
```

* Stop all containers:

```bash
docker stop $(docker ps -q)
```

* Remove all containers:

```bash
docker rm $(docker ps -aq)
```

---
*End of cheat sheet — happy containerizing!*
