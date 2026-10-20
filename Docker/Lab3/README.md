# Lab 3: Creating a Docker Image for a Java Application

- **App:** Calculator
- **Source code:** https://github.com/Ibrahim-Adel15/CalculatorMavenApp.git

## Objective

Containerize the calculator Java application with Docker in two different ways (build inside Docker vs. build locally), then compare the resulting image sizes.

## Lab Tasks

### Part 1: Build Inside Docker

- [ ] Write a Dockerfile using a Maven image with Java 17.
- [ ] Create a working directory and a non-root user.
- [ ] Copy the source code and build the application using `mvn package`.
- [ ] Run the generated JAR file and expose port 8080.
- [ ] Build an image named `app1` and note its size.
- [ ] Run `container1`, verify the application, then delete the container and image.

### Part 2: Build Locally

- [ ] Build the application locally using Maven.
- [ ] Write a Dockerfile using a Java 17 runtime image.
- [ ] Create a working directory and a non-root user.
- [ ] Copy the generated JAR file into the image and expose port 8080.
- [ ] Build an image named `app2` and note its size.
- [ ] Run `container2`, verify the application, then delete the container and image.

### Bonus

- [ ] Compare the image sizes and explain the differences between the two approaches.

---

## Screenshots

Terminal screenshots go in `images/` in this folder. Suggested moments to capture:

| Step | What to capture |
|------|-----------------|
| Start | `docker version` / `docker info` showing the installed version |
| Part 1 Dockerfile | the Dockerfile content on screen before building |
| Part 1 build | `docker build -t app1 .` full output |
| Part 1 sizes | `docker images` showing app1 size |
| Part 1 run | `docker run` command + the application output in the container |
| Part 1 cleanup | `docker rm` and `docker rmi` output |
| Part 2 local build | `mvn package` output on the host |
| Part 2 Dockerfile | the Dockerfile content before building |
| Part 2 build | `docker build -t app2 .` full output |
| Part 2 sizes | `docker images` showing app2 size |
| Part 2 run | `docker run` + application output |
| Part 2 cleanup | `docker rm` and `docker rmi` output |
| Bonus | `docker images` side by side or both sizes for the comparison |

When all screenshots are in `images/`, the README steps and the size comparison can be written around them.
