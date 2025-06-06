
#!/bin/bash
set -e
docker kill windmill_server
docker kill windmill_worker

docker rm windmill_server
docker rm windmill_worker

 docker start windmill_db windmill_server windmill_worker
 docker kill windmill_db windmill_server windmill_worker

 WM_IMAGE=ghcr.io/windmill-labs/windmill:main

 docker exec -it --user root windmill_server /bin/sh
 
# sample env
DATABASE_URL=postgres://postgres:changeme@localhost:5432/windmill?sslmode=disable
JSON_FMT=true
DISABLE_RESPONSE_LOGS=false
BASE_URL=http://156.244.1.242:8000
CREATE_WORKSPACE_REQUIRE_SUPERADMIN=true



# Jalankan kontainer PostgreSQL
docker run -d \
  --name windmill_db \
  -e POSTGRES_PASSWORD=changeme \
  -e POSTGRES_DB=windmill \
  -p 5432:5432 \
  -v windmill_db_data:/var/lib/postgresql/data \
  --health-cmd="pg_isready -U postgres" \
  --health-interval=10s \
  --health-timeout=5s \
  --health-retries=5 \
  postgres:14

WM_IMAGE="ghcr.io/windmill-labs/windmill:main"

# Jalankan kontainer Windmill Server
docker run -d \
  --name windmill_server \
  --link windmill_db:db \
  -e DATABASE_URL=postgres://postgres:changeme@db/windmill?sslmode=disable \
  -e MODE=server \
  -p 8000:8000 \
  --env-file .env \
  -p 2525:2525 \
  ${WM_IMAGE}

# Jalankan kontainer Windmill Worker
docker run -d \
  --name windmill_worker \
  --link windmill_db:db \
  -e DATABASE_URL=postgres://postgres:changeme@db/windmill?sslmode=disable \
  -e MODE=worker \
  -e WORKER_GROUP=default \
  ${WM_IMAGE}


 #menampilkan logs
docker logs -f windmill_server 2>&1 | sed 's/^/[SERVER] /' & \
docker logs -f windmill_worker 2>&1 | sed 's/^/[WORKER] /' & \
wait



docker run -d \
  --name windmill_server \
  --link windmill_db:db \
  -e DATABASE_URL=postgres://postgres:changeme@db/windmill?sslmode=disable \
  -e MODE=server \
  -p 80:80 \
  --env-file .env \
  -p 2525:2525 \
  windmill-custom


git pull origin main
docker build -f DockerfileNginx -t windmill-custom .
docker kill windmill_server
docker rm windmill_server
docker run -d \
  --name windmill_server \
  --link windmill_db:db \
  -e DATABASE_URL=postgres://postgres:changeme@db/windmill?sslmode=disable \
  -e MODE=server \
  -p 80:80 \
  --env-file .env \
  -p 2525:2525 \
  windmill-custom
 
  docker logs windmill_server -f | grep "INBOUND_REQUEST"
# docker build -t windmill-custom .
# docker run -d \
#   --name windmill_server \
#   --link windmill_db:db \
#   -e DATABASE_URL=postgres://postgres:changeme@db/windmill?sslmode=disable \
#   -e MODE=server \
#   -p 80:80 \
#   --env-file .env \
#   -p 2525:2525 \
#   windmill-custom
