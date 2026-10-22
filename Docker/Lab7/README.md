# Lab 7: Multi-Network Microservices, Volumes, and Bind Mounts

- **Source code:** https://github.com/Ibrahim-Adel15/MicroserviceApp.git (cloned into this folder: `MicroserviceApp/`)
- **Services:** frontend (port 3000), backend (port 5000), notification (port 5001) — all Flask.

## Lab Tasks

- [ ] Clone the application code from https://github.com/Ibrahim-Adel15/MicroserviceApp.git.
- [ ] Create Dockerfiles for the frontend, backend, and notification services, then build their images.
- [ ] Create two bridge networks with separate subnets: frontend-backend and backend-notification.
- [ ] Create two docker volumes for backend and notification logs.
- [ ] Create host directory to persist backend application data and configure a bind mount to map it to the appropriate path inside the backend container.
- [ ] Run the notification container on backend-notification.
- [ ] Run the backend container on both networks, configure the notification service URL.
- [ ] Run the frontend container on frontend-backend, publish port 8080, and configure the backend URL.
- [ ] Access the web page and verify that messages can be created and retrieved.

## Screenshot Moments

| File | What it shows |
|---|---|
| `images/lab7-files.png` | The cloned repo: frontend, backend, notification |
| `images/lab7-dockerfile-frontend.png` | Frontend Dockerfile |
| `images/lab7-dockerfile-backend.png` | Backend Dockerfile |
| `images/lab7-dockerfile-notification.png` | Notification Dockerfile |
| `images/lab7-build1.png` | Building the frontend and backend images |
| `images/lab7-build2.png` | Building the notification image, docker images |
| `images/lab7-networks.png` | The two bridge networks created with separate subnets |
| `images/lab7-volumes.png` | The two volumes for the logs |
| `images/lab7-run-notification.png` | Notification container on backend-notification |
| `images/lab7-run-backend.png` | Backend on both networks with bind mount and NOTIFICATION_URL |
| `images/lab7-run-frontend.png` | Frontend on frontend-backend, port 8080, BACKEND_URL |
| `images/lab7-web.png` | The web page loaded from http://localhost:8080 |
| `images/lab7-web-message.png` | A message created and retrieved in the browser |
| `images/lab7-persist.png` | The message file on the host through the bind mount |
| `images/lab7-logs.png` | Backend and notification logs recorded in the volumes |
| `images/lab7-network-inspect.png` | Network inspect: subnets and which container is on which network |
