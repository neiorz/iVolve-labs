# Lab 8: Containerized Node.js and MySQL Stack Using Docker Compose

![Lab 8 instructions slide: the tasks of this lab](images/lab8-instructions.png)

- **Source code:** https://github.com/Ibrahim-Adel15/iVolveApp.git (cloned into this folder: `iVolveApp/`)
- **Stack:** Node.js/Express app on port 3000 + MySQL 8, wired together with `docker-compose.yml`
- **Docker Hub:** `nourz1/ivolve-app`

## Objective

One compose file to run the application and its database together: the app builds from its Dockerfile, both services join a custom network, the logs live in a volume, the MySQL files live in `db_data` — and the finished image ends up in my Docker Hub repository.

---

## The Application

```bash
cd ~/Desktop/iVolve-labs/Docker/Lab8
find iVolveApp -type f | sort
cat iVolveApp/package.json
```

![find output listing db.js, Dockerfile, the frontend files, package.json and server.js, followed by the package.json contents](images/lab8-files.png)

An Express app called `ecommerce-ivolve` (express, mysql2, morgan, dotenv). What it demands from its environment:

```bash
grep -n "DB_\|'ivolve'" iVolveApp/server.js
```

![grep output: SHOW DATABASES LIKE 'ivolve', the DB_HOST, DB_USER and DB_PASSWORD variables, and the connected message](images/lab8-dbcode.png)

Three rules are written into the code: the connection is built from `DB_HOST`/`DB_USER`/`DB_PASSWORD`, a database literally named `ivolve` must exist before the app is satisfied (it retries every 5 seconds until it finds it), and only then does it start listening on port 3000. It also writes request logs to `/app/logs/access.log` through morgan.

## The Dockerfile

![Dockerfile in the editor: node:18-alpine, npm install, EXPOSE 3000, CMD node server.js](images/lab8-dockerfile.png)

Came with the repo: `node:18-alpine`, `npm install`, `EXPOSE 3000`, `CMD ["node", "server.js"]`.

## The Compose File

![docker-compose.yml in the editor: app and db services, the ivolve-net network, and the app-logs and db_data volumes](images/lab8-compose.png)

What I put in `docker-compose.yml`, piece by piece:

- **app** — builds from `./iVolveApp` and is tagged `ivolve-app`, publishes `3000:3000`, receives the database variables with `DB_HOST: db` (the other service's hostname), mounts `app-logs` on `/app/logs`, `depends_on: db`, joins `ivolve-net`.
- **db** — `mysql:8` with `MYSQL_DATABASE: ivolve` (this is what creates the database the app waits for), user `ivolve`/`ivolve123`, a root password, and `db_data` mounted on `/var/lib/mysql`.
- **network** — `ivolve-net` with `name: ivolve-net`, so the network in docker is called exactly that, bridge driver.
- **volumes** — `app-logs` for the logs, `db_data` for the database, with `name: db_data` for the same exact-name reason.

## Start the Stack

```bash
docker compose up -d
docker compose ps
```

![docker compose ps: lab8-app-1 up with 0.0.0.0:3000 mapped and lab8-db-1 up with 3306 only](images/lab8-up.png)

Both containers Up. Only the app publishes a port to my machine (`0.0.0.0:3000->3000/tcp`); the database shows just `3306/tcp, 33060/tcp` — it stays inside the compose network where nobody else can reach it.

## The App Finds the Database

```bash
docker compose logs app --tail=8
```

![app logs: Attempting to connect to MySQL, then Connected to MySQL and 'ivolve' DB found, then Server started](images/lab8-logs1.png)

The app really does wait for its database: it attempted the connection, found `ivolve` (the MySQL container created it from `MYSQL_DATABASE` on first boot), and only after that announced that the server started on port 3000.

## Verify: Functionality and DB Connectivity

```bash
curl http://localhost:3000/health
docker compose exec db mysql -uivolve -pivolve123 -e "SHOW DATABASES LIKE 'ivolve';"
```

![terminal with the health answer and mysql listing the ivolve database, next to the same health URL open in the browser](images/lab8-verify.png)

`/health` runs a query through the app's own MySQL connection, so its answer means app-to-database works end to end — and I opened the same URL in the browser. From the database side, `SHOW DATABASES LIKE 'ivolve';` comes back with exactly one row: `ivolve`. (The password warning from the mysql client is normal.)

## The Web Page

```bash
firefox http://localhost:3000
```

![the iVolve page served on port 3000 with the logo and the five offices](images/lab8-web.png)

The page the container serves on port 3000 — the iVolve logo and the five office locations.

## Logs and Data, Both Persisted

```bash
docker compose exec app tail -3 /app/logs/access.log
docker volume ls | grep -E "db_data|app-logs"
```

![access.log lines from 172.25.0.1 recording the page requests, and volume ls showing db_data and lab8_app-logs](images/lab8-logs2.png)

morgan recorded my browser's requests — arriving from `172.25.0.1`, my host through the published port — into `/app/logs/access.log`, which lives on the `lab8_app-logs` volume rather than in the container's own filesystem. And `docker volume ls` shows **db_data** holding MySQL's files at `/var/lib/mysql`, sitting next to the logs volume.

## The Network

```bash
docker network inspect ivolve-net --format '{{.Name}} {{range .IPAM.Config}}{{.Subnet}}{{end}}'
docker compose exec app ping -c 2 db
```

![ivolve-net showing subnet 172.25.0.0/16 and a ping from the app container to db with 0 percent loss](images/lab8-network.png)

One custom network: `ivolve-net` on `172.25.0.0/16`, with both containers attached. From inside the app container, `db` resolves to `172.25.0.2` and answers ping with 0% packet loss — that name resolution is exactly what the app's `DB_HOST: db` relies on.

## Tag and Push to Docker Hub

```bash
docker tag ivolve-app nourz1/ivolve-app
docker images | grep ivolve
docker push nourz1/ivolve-app
```

![docker images showing nourz1/ivolve-app sharing the image ID with ivolve-app, and the push ending in the digest line](images/lab8-push.png)

`docker tag` prints nothing when it works — the proof is in `docker images`: `nourz1/ivolve-app:latest` and `ivolve-app:latest` carry the same image ID `119148fe94e4`. The push reused layers I already had in Docker Hub from my earlier images and ended with `latest: digest: sha256:119148fe94e4...`.

## The Repository on Docker Hub

![Docker Hub page for nourz1/ivolve-app showing the latest tag pushed minutes ago](images/lab8-dockerhub.png)

`hub.docker.com/r/nourz1/ivolve-app` — public, one tag (`latest`), pushed minutes earlier. Anyone can get it with `docker pull nourz1/ivolve-app`.

---

One file turned a Node app and a MySQL server into a running product: compose built the image, `MYSQL_DATABASE` satisfied the app's hard requirement on the `ivolve` database, the custom network supplied the `db` hostname, the two volumes kept the logs and the database files outside the containers — and the same image now lives on my Docker Hub as `nourz1/ivolve-app`.
