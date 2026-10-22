# Lab 6: Docker Environment Variables and Resource Management

- **Source code:** https://github.com/Ibrahim-Adel15/PythonApp.git
- **App:** Python application, port 5000.

## Objective

Run the same Python app three ways — environment variables passed on the run command, an env file, and variables baked into the image — while capping the container at 1 CPU and 256 MB, and verify each variation.

## Lab Tasks

- [ ] Clone the application code from https://github.com/Ibrahim-Adel15/PythonApp.git.
- [ ] Create a Dockerfile using the python:3.12-slim base image, install the application dependencies, and configure the application to run on port 5000.
- [ ] Build ivolve1 Docker image.
- [ ] Run a container with name container1, map port 5000, and configure the environment variables APP_NAME=iVolveApp1 and APP_ENV=stg.
- [ ] Limit the container resources to 1 CPU and 256 MB of memory.
- [ ] Verify that the application is working by accessing http://localhost:5000.
- [ ] Verify the environment variables configured inside the container.
- [ ] Monitor the container's CPU and memory usage using docker stats cont1.
- [ ] Create env.txt file with APP_NAME=iVolveApp2 and APP_ENV=prod.
- [ ] Run a container with name container2, map port 5000, and load the environment variables from env.txt.
- [ ] Create a new Docker Image with the following environment variables hardcoded in the Dockerfile: APP_NAME=iVolveApp3 and APP_ENV=dev.
- [ ] Run a container with name container2, map port 5000, and validate the environment variables from Dockerfile.

## Screenshot Moments

| # | What you do | Command | Screenshot file |
|---|---|---|---|
| 1 | Look at the application code | `ls -la`, `cat` the app and its dependencies | `lab6-app.png` |
| 2 | The Dockerfile | `cat Dockerfile` | `lab6-dockerfile.png` |
| 3 | Build ivolve1 | `docker build -t ivolve1 .`, `docker images ivolve1` | `lab6-build1.png` |
| 4 | Run container1 with env vars and resource limits | `docker run -d --name container1 -p 5000:5000 -e APP_NAME=iVolveApp1 -e APP_ENV=stg --cpus=1 -m=256m ivolve1` | `lab6-run1.png` |
| 5 | Verify the app answers | `curl http://localhost:5000` | `lab6-verify1.png` |
| 6 | Verify env vars inside the container | `docker exec container1 env \| grep APP_` | `lab6-env1.png` |
| 7 | Monitor CPU and memory | `docker stats container1` (screenshot, then Ctrl+C) | `lab6-stats.png` |
| 8 | Create env.txt | create + `cat env.txt` | `lab6-envtxt.png` |
| 9 | Run container2 from env.txt | stop container1, `docker run ... --env-file env.txt`, `curl`, env check | `lab6-run2.png` |
| 10 | The hardcoded Dockerfile | `cat Dockerfile.hardcoded` | `lab6-dockerfile2.png` |
| 11 | Build the second image | `docker build -f Dockerfile.hardcoded -t ivolve2 .` | `lab6-build2.png` |
| 12 | Replace container2 and validate | stop/rm container2, run from the new image, `curl`, env check | `lab6-run3.png` |

Notes for the run: both containers need port 5000, so each one is stopped before the next starts (same situation as Lab 4's port 8080); `docker stats` streams forever — screenshot it, then Ctrl+C. Steps and screenshots get added here after the run, same style as the other labs.
