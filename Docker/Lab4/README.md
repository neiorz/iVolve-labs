# Lab 4: Docker Image Optimization and Export/Load

- **Source code:** https://github.com/Ibrahim-Adel15/ImageOptimization-.git (cloned into this folder: `ImageOptimization-/`)
- **App:** Spring Boot (Java 17), one HTTP endpoint on port 8080.

## Objective

Shrink a Docker image with a multi-stage build and a non-root user, then move an image between Docker hosts with `docker save` / `docker load`.

## Lab Tasks

- [ ] Clone the application code from https://github.com/Ibrahim-Adel15/ImageOptimization-.git. Build an image from the existing Dockerfile with name `image1`.
- [ ] Note the image size and run a container named `container1` from `image1`.
- [ ] Verify that the application is working, then stop and delete the container.
- [ ] Write a multi-stage Dockerfile and configure the application to run as a non-root user.
- [ ] Build the optimized image as `image2` and compare its size with `image1`.
- [ ] Run a container named `container2` from `image2` and verify that the application is working and running as a non-root user.
- [ ] Stop and delete `container2`.
- [ ] Save `image2` as a TAR file named `lab-image.tar`.
- [ ] Delete `image2` from the local Docker host.
- [ ] Load the image from `image2.tar` and verify that it has been restored.
- [ ] Verify the loaded image exists in the local Docker host.

Note on the slide: the save task names the file `lab-image.tar`, the load task says `image2.tar` — it is one file, so it is `lab-image.tar` everywhere.

## Screenshot Moments

| # | What you do | Command | Screenshot file |
|---|---|---|---|
| 1 | Look at the existing Dockerfile | `cat Dockerfile` | `lab4-dockerfile1.png` |
| 2 | Build image1 | `docker build -t image1 .` | `lab4-build1.png` |
| 3 | Note image1's size | `docker images` | `lab4-size1.png` |
| 4 | Run and verify container1 | `docker run -d --name container1 -p 8080:8080 image1`, then `docker logs container1` and `curl http://localhost:8080` | `lab4-run1.png` |
| 5 | Stop and delete container1 | `docker stop container1`, `docker rm container1` | `lab4-cleanup1.png` |
| 6 | Look at the multi-stage Dockerfile | `cat Dockerfile.multistage` | `lab4-multistage.png` |
| 7 | Build image2 | `docker build -f Dockerfile.multistage -t image2 .` | `lab4-build2.png` |
| 8 | Compare the sizes | `docker images` | `lab4-compare.png` |
| 9 | Run and verify container2 (app + non-root) | `docker run -d --name container2 -p 8080:8080 image2`, then `docker exec container2 id` and `curl http://localhost:8080` | `lab4-run2.png` |
| 10 | Stop and delete container2 | `docker stop container2`, `docker rm container2` | `lab4-cleanup2.png` |
| 11 | Save image2 as TAR | `docker save -o lab-image.tar image2`, `ls -lh lab-image.tar` | `lab4-save.png` |
| 12 | Delete image2 | `docker rmi image2` | `lab4-rmi.png` |
| 13 | Load from the TAR | `docker load -i lab-image.tar` | `lab4-load.png` |
| 14 | Verify it is back | `docker images` | `lab4-loaded.png` |

Steps and screenshots get added here after the run — same style as Lab 1 and Lab 3: screenshots carry the explanation.
