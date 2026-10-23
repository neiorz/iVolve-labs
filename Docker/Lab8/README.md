# Lab 8: Containerized Node.js and MySQL Stack Using Docker Compose

- **Source code:** https://github.com/Ibrahim-Adel15/iVolveApp.git (cloned into this folder: `iVolveApp/`)
- **Stack:** Node.js/Express app (port 3000) + MySQL 8, wired together with `docker-compose.yml`.

## Lab Tasks

- [ ] Clone the application requirement from https://github.com/Ibrahim-Adel15/iVolveApp.git.
- [ ] The application requires a MySQL connection and a database named ivolve to start successfully.
- [ ] Create docker-compose.yml with:
  - [ ] App: Build from Dockerfile, map port 3000, configure database environment variables, and persist logs.
  - [ ] Database: Use MySQL, configure required environment variables, and persist data using db_data.
  - [ ] Network: Create a custom network named ivolve-net for service communication.
  - [ ] Volumes: Persist application logs at /app/logs/ and database data at /var/lib/mysql.
- [ ] Start the services and verify application functionality and connectivity to the DB.
- [ ] Build and tag the application image with your Docker Hub username, then push it to your repository.

## Screenshot Moments

| File | What it shows |
|---|---|
| `images/lab8-files.png` | The cloned repo and package.json |
| `images/lab8-dbcode.png` | The app's database environment variables in server.js |
| `images/lab8-dockerfile.png` | The application Dockerfile |
| `images/lab8-compose.png` | docker-compose.yml in the editor |
| `images/lab8-up.png` | docker compose up -d and docker compose ps |
| `images/lab8-logs1.png` | App logs: connecting to MySQL, then connected to ivolve |
| `images/lab8-verify.png` | curl /health plus the ivolve database listed inside MySQL |
| `images/lab8-web.png` | The web page on port 3000 |
| `images/lab8-logs2.png` | access.log through the volume, docker volume ls |
| `images/lab8-network.png` | ivolve-net inspect, ping from app to db |
| `images/lab8-tag.png` | The image tagged with the Docker Hub username |
| `images/lab8-push.png` | docker push to Docker Hub |
