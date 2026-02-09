# Project: Docker-based Nginx-Tomcat Load Balancing with Prometheus/Grafana Monitoring

## Project Overview

This project implements a highly available and scalable web service architecture using Docker containers. It features Nginx as a load balancer and reverse proxy distributing traffic to multiple Apache Tomcat Web Application Servers (WAS). Real-time monitoring is achieved through Prometheus for metric collection and Grafana for data visualization. The goal is to detect potential bottlenecks and facilitate efficient troubleshooting.

**Key Components:**
*   **Nginx:** Acts as a load balancer and reverse proxy for distributing incoming traffic.
*   **Tomcat WAS:** Hosts the web applications, with multiple instances for load balancing.
*   **Prometheus:** Collects system metrics from Nginx, Tomcat (via JMX Exporter), and the host (via Node Exporter).
*   **Grafana:** Visualizes the collected metrics through interactive dashboards, providing insights into system health and performance.

**Technology Stack:**
*   **Containerization:** Docker, Docker Compose
*   **Web Server/Load Balancer:** Nginx
*   **Web Application Server:** Apache Tomcat (JDK 11)
*   **Monitoring:** Prometheus, Grafana
*   **Exporters:** JMX Exporter (for Tomcat), Nginx Exporter, Node Exporter

## Building and Running

The project uses Docker Compose to manage and orchestrate the multi-container application.

### Prerequisites

*   Docker Desktop (Windows/macOS) or Docker Engine (Linux)
*   Docker Compose

### To Start the Services

1.  Navigate to the project root directory.
2.  Run the following command to build and start all services in detached mode:
    ```bash
    docker-compose up -d
    ```

### Accessing Services

*   **Web Application (via Nginx):** `http://localhost:80`
*   **Prometheus UI:** `http://localhost:9090`
*   **Grafana UI:** `http://localhost:3000` (Default credentials: `admin` / `admin`)

### To Stop the Services

```bash
docker-compose stop
```

### To Stop and Remove Containers

```bash
docker-compose down
```

### To Stop and Remove Containers with Volumes (Data will be lost)

```bash
docker-compose down --volumes
```

## Development Conventions

*   **Container Orchestration:** Docker Compose is used for defining and running the multi-container Docker application.
*   **Dockerfiles:** Individual Dockerfiles (`nginx/Dockerfile`, `tomcat/Dockerfile`) are used to build custom images for Nginx and Tomcat.
*   **Configuration Files:**
    *   `nginx/nginx.conf`: Nginx load balancer and reverse proxy configuration.
    *   `prometheus/prometheus.yml`: Prometheus scrape configurations for various exporters.
    *   `tomcat/jmx_exporter_config.yml`: JMX Exporter configuration for Tomcat JVM metrics.
*   **Monitoring Integration:** Prometheus and Grafana are integral parts of the development and operational workflow for performance analysis.
*   **Package Management (inside Docker):** `apt-get` is used for installing dependencies within the Debian-based Docker images. `wget` is used for downloading JMX Exporter.
*   **Application Deployment:** `your-app.war` is expected to be copied into the Tomcat webapps directory.
