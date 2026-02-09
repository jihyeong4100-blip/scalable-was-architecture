# Docker 기반 Nginx-Tomcat 로드밸런싱 WAS 환경 및 Prometheus/Grafana 모니터링 시스템 구현

## 🚀 프로젝트 설명

이 프로젝트는 Docker 컨테이너를 활용하여 고가용성 및 확장성을 갖춘 웹 서비스 아키텍처를 구축하고, Prometheus와 Grafana를 이용한 실시간 모니터링 시스템을 구현하는 것을 목표로 합니다. 리눅스 환경에서 Nginx를 로드밸런서 및 리버스 프록시로, Apache Tomcat을 WAS로 사용하여 다수의 WAS 인스턴스에 트래픽을 분산 처리합니다. 또한, 시스템 전반의 성능 지표(Nginx 트래픽, Tomcat WAS 상태, 컨테이너 자원 사용량 등)를 수집 및 시각화하여 잠재적인 병목 현상을 사전에 감지하고 효율적으로 트러블슈팅할 수 있는 환경을 제공합니다.

**주요 목표:**
*   Docker를 이용한 Nginx 및 Tomcat WAS 컨테이너화 및 배포 자동화
*   Nginx 로드밸런서를 통한 트래픽 분산 및 고가용성 확보
*   Prometheus를 이용한 시스템 메트릭 수집
*   Grafana를 이용한 실시간 성능 대시보드 구축 및 시각화
*   모니터링 데이터를 기반으로 한 성능 병목 현상 식별 및 트러블슈팅 역량 강화

## ⚙️ 아키텍처 구성

프로젝트는 다음과 같은 컴포넌트들로 구성됩니다. 모든 컴포넌트는 Docker 컨테이너로 실행됩니다.

*   **Nginx (Load Balancer & Reverse Proxy):** 외부 요청을 받아 여러 Tomcat WAS 컨테이너로 트래픽을 분산합니다. 정적 파일을 서빙하거나 SSL/TLS 오프로딩 역할도 수행할 수 있습니다.
*   **Tomcat WAS (Web Application Server):** 실제 웹 애플리케이션이 배포되고 실행되는 환경입니다. 트래픽 분산을 위해 다수의 인스턴스로 구성됩니다.
*   **Prometheus (Monitoring System):** Nginx, Tomcat, 컨테이너 호스트 등에서 메트릭을 수집하는 시계열 데이터베이스입니다. `nginx-exporter`, `jmx-exporter`, `node-exporter`를 통해 각 컴포넌트의 지표를 스크랩합니다.
*   **Grafana (Data Visualization):** Prometheus에서 수집된 데이터를 시각화하여 직관적인 대시보드를 제공합니다. 시스템 상태를 한눈에 파악하고 성능 문제를 분석하는 데 사용됩니다.
*   **Node Exporter:** 호스트 머신의 CPU, Memory, Disk I/O 등 기본적인 시스템 메트릭을 Prometheus가 수집할 수 있도록 노출합니다.
*   **JMX Exporter:** Tomcat WAS 내부의 JVM 및 애플리케이션 관련 메트릭을 Prometheus가 수집할 수 있도록 노출합니다.
*   **Nginx Exporter:** Nginx의 트래픽, 연결 상태 등 Nginx 관련 메트릭을 Prometheus가 수집할 수 있도록 노출합니다.

```
+------------------+
|    Client        |
+--------+---------+
         |
         v
+--------+---------+
|     Nginx        |  (Docker Container)
| (Load Balancer)  |
+--------+---------+
         | Round-robin, IP Hash, etc.
         v
+--------+---------+     +--------+---------+
| Tomcat WAS #1    |     | Tomcat WAS #2    |
| (Docker Container)|     | (Docker Container)|
+--------+---------+     +--------+---------+
         ^                   ^
         |                   |
         +-------------------+
         | (Metrics via JMX Exporter)
         v
+--------+---------+
|   Prometheus     |  (Docker Container)
| (Metrics Scraper)|
+--------+---------+
         |
         v
+--------+---------+
|    Grafana       |  (Docker Container)
| (Visualization)  |
+--------+---------+
```

## 🛠️ 주요 기술 스택

*   **Operating System:** Linux (Docker Host)
*   **Containerization:** Docker, Docker Compose
*   **Web Server / Load Balancer:** Nginx
*   **Web Application Server:** Apache Tomcat
*   **Monitoring:** Prometheus, Grafana
*   **Exporters:** JMX Exporter (for Tomcat), Nginx Exporter, Node Exporter

## 📝 상세 구성

### `docker-compose.yml`

```yaml
version: '3.8'

services:
  nginx:
    build:
      context: ./nginx
      dockerfile: Dockerfile
    ports:
      - "80:80"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
    depends_on:
      - tomcat1
      - tomcat2
    networks:
      - app-network

  tomcat1:
    build:
      context: ./tomcat
      dockerfile: Dockerfile
    environment:
      - JMX_PORT=9010 # JMX Exporter용 포트
    ports:
      - "8081:8080" # WAS 포트
      - "9010:9010" # JMX Exporter 포트
    networks:
      - app-network

  tomcat2:
    build:
      context: ./tomcat
      dockerfile: Dockerfile
    environment:
      - JMX_PORT=9011 # JMX Exporter용 포트
    ports:
      - "8082:8080" # WAS 포트
      - "9011:9011" # JMX Exporter 포트
    networks:
      - app-network

  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    volumes:
      - ./prometheus/prometheus.yml:/etc/prometheus/prometheus.yml:ro
      - prometheus_data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
    ports:
      - "9090:9090"
    networks:
      - app-network

  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_USER=admin
      - GF_SECURITY_ADMIN_PASSWORD=admin # 기본 비밀번호, 실제 운영에서는 변경 권장
    volumes:
      - grafana_data:/var/lib/grafana
    depends_on:
      - prometheus
    networks:
      - app-network

  nginx-exporter:
    image: nginx/nginx-prometheus-exporter:latest
    ports:
      - "9113:9113"
    environment:
      - NGINX_SCRAPE_URI=http://nginx/nginx_status # Nginx status 페이지 URL
    depends_on:
      - nginx
    networks:
      - app-network

  node-exporter:
    image: prom/node-exporter:latest
    ports:
      - "9100:9100"
    networks:
      - app-network

volumes:
  prometheus_data:
  grafana_data:

networks:
  app-network:
    driver: bridge
```

### Nginx Configuration (`nginx/nginx.conf`)

Nginx는 로드밸런서 역할을 수행하며, `/nginx_status` 경로를 통해 Prometheus Exporter가 메트릭을 수집할 수 있도록 설정됩니다.

```nginx
worker_processes 1;

events {
    worker_connections 1024;
}

http {
    include mime.types;
    default_type application/octet-stream;
    sendfile on;
    keepalive_timeout 65;

    upstream tomcat_backends {
        server tomcat1:8080; # docker-compose 서비스 이름
        server tomcat2:8080;
    }

    server {
        listen 80;
        server_name localhost;

        # Nginx Prometheus Exporter를 위한 status 페이지
        location /nginx_status {
            stub_status on;
            allow 127.0.0.1; # Prometheus Exporter가 실행되는 IP 또는 컨테이너 네트워크 IP
            deny all;
        }

        location / {
            proxy_pass http://tomcat_backends;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
    }
}
```

### Tomcat WAS (`tomcat/Dockerfile`)

Tomcat 컨테이너는 애플리케이션 배포와 함께 JMX Exporter를 포함하여 Prometheus가 JVM 메트릭을 수집할 수 있도록 합니다.
(예시: `your-app.war`를 `/usr/local/tomcat/webapps/`에 배포하고, `jmx_exporter`를 구성)

```dockerfile
FROM tomcat:9.0-jdk11-openjdk

COPY ./your-app.war /usr/local/tomcat/webapps/

# JMX Exporter 다운로드 및 설정
# 실제 운영에서는 특정 버전 명시 및 내부망을 통해 관리
RUN apt-get update && apt-get install -y wget && 
    wget -O /usr/local/tomcat/lib/jmx_prometheus_javaagent.jar 
    https://repo1.maven.org/maven2/io/prometheus/jmx/jmx_prometheus_javaagent/0.17.2/jmx_prometheus_javaagent-0.17.2.jar && 
    rm -rf /var/lib/apt/lists/*

# JMX Exporter 설정 파일 복사
COPY ./jmx_exporter_config.yml /usr/local/tomcat/conf/jmx_exporter_config.yml

# CATALINA_OPTS에 JMX Exporter 추가
ENV CATALINA_OPTS="-javaagent:/usr/local/tomcat/lib/jmx_prometheus_javaagent.jar=9010:/usr/local/tomcat/conf/jmx_exporter_config.yml"

EXPOSE 8080
EXPOSE 9010 # JMX Exporter 포트
```
**`tomcat/jmx_exporter_config.yml` 예시:** (기본 JVM 메트릭을 수집하도록 설정)
```yaml
# jmx_exporter_config.yml
startDelaySeconds: 0
hostPort: 127.0.0.1:9010
beans:
  - Jvm:
      - type: "java.lang<type=OperatingSystem>.*"
      - type: "java.lang<type=Memory>.*"
      - type: "java.lang<type=GarbageCollector,name=*>.*"
      - type: "java.lang<type=Threading>.*"
  - Catalina:
      - type: "Catalina<type=GlobalRequestProcessor,name=*>.*"
      - type: "Catalina<type=ThreadPool,name=*>.*"
```

### Prometheus Configuration (`prometheus/prometheus.yml`)

Prometheus는 각 서비스에서 메트릭을 스크랩하도록 설정됩니다. `scrape_configs` 섹션에 Nginx Exporter, JMX Exporter (Tomcat), Node Exporter에 대한 설정을 추가합니다.

```yaml
global:
  scrape_interval: 15s # 모든 타겟에 대해 15초마다 스크랩

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'nginx-exporter'
    static_configs:
      - targets: ['nginx-exporter:9113'] # docker-compose 서비스 이름

  - job_name: 'tomcat-jmx'
    static_configs:
      - targets: ['tomcat1:9010', 'tomcat2:9011'] # tomcat1, tomcat2 서비스의 JMX Exporter 포트

  - job_name: 'node-exporter'
    static_configs:
      - targets: ['node-exporter:9100'] # docker-compose 서비스 이름
```

## ▶️ 실행 방법

이 프로젝트는 Docker와 Docker Compose를 사용하여 관리됩니다.

### 📋 사전 요구 사항

*   Docker Desktop (Windows/macOS) 또는 Docker Engine (Linux) 설치
*   Docker Compose 설치 (Docker Desktop에 포함되어 있을 수 있음)

### 🚀 프로젝트 실행

1.  **프로젝트 클론:**
    ```bash
    git clone [Your-Repository-URL]
    cd [Your-Project-Directory]
    ```
2.  **프로젝트 구조 확인:**
    `docker-compose.yml`, `nginx/`, `prometheus/`, `tomcat/` 디렉토리가 올바르게 구성되어 있는지 확인합니다.
    *   `nginx/nginx.conf`: Nginx 설정 파일
    *   `tomcat/Dockerfile`: Tomcat Docker 이미지 빌드 파일 (필요시 `your-app.war`를 준비하고 `jmx_exporter_config.yml` 확인)
    *   `prometheus/prometheus.yml`: Prometheus 설정 파일
3.  **Docker Compose를 이용한 서비스 실행:**
    ```bash
    docker-compose up -d
    ```
    `-d` 옵션은 백그라운드에서 컨테이너를 실행합니다.

### 🌐 서비스 접속

*   **웹 애플리케이션 (Nginx):** `http://localhost:80`
    *   Nginx 로드밸런서를 통해 Tomcat WAS에 접근합니다.
*   **Prometheus UI:** `http://localhost:9090`
    *   Prometheus 서버의 웹 인터페이스에서 수집된 메트릭을 쿼리하고 확인할 수 있습니다.
*   **Grafana UI:** `http://localhost:3000`
    *   기본 로그인 정보: `admin` / `admin` (로그인 후 비밀번호 변경을 권장합니다.)
    *   Grafana에 로그인 후, Prometheus 데이터 소스를 추가하고, Nginx, Tomcat, Node Exporter 관련 대시보드를 임포트하거나 직접 생성하여 모니터링을 시작할 수 있습니다.

### 🛑 서비스 중지 및 삭제

*   **서비스 중지:**
    ```bash
    docker-compose stop
    ```
*   **서비스 중지 및 컨테이너 삭제:**
    ```bash
    docker-compose down
    ```
*   **볼륨까지 모두 삭제:** (데이터가 영구적으로 삭제되므로 주의)
    ```bash
    docker-compose down --volumes
    ```

## 📊 모니터링 대시보드 (Grafana)

Grafana에 로그인한 후, 다음과 같은 대시보드를 임포트하거나 직접 구성하여 시스템을 모니터링할 수 있습니다.

*   **Nginx 대시보드:** Nginx Requests, Active Connections, Reading/Writing/Waiting Connections 등 Nginx 트래픽 및 성능 지표를 모니터링합니다. (예: Grafana.com ID `13340` - Nginx Prometheus Exporter)
*   **Tomcat/JVM 대시보드:** JVM Heap/Non-Heap Usage, Garbage Collection Activity, Thread Pool Status, Request Processing Time 등 Tomcat WAS의 내부 상태 및 성능을 모니터링합니다. (예: Grafana.com ID `8709` - JVM Micrometer)
*   **Node Exporter (Host/Container) 대시보드:** CPU Usage, Memory Usage, Disk I/O, Network I/O 등 호스트 및 컨테이너의 기본 시스템 자원 사용량을 모니터링합니다. (예: Grafana.com ID `1860` - Node Exporter Full)

이 대시보드들을 통해 서비스의 현재 상태를 실시간으로 파악하고, 트래픽 변화에 따른 자원 사용량 변화를 추적하여 잠재적인 문제를 조기에 발견할 수 있습니다.

## ⚠️ 트러블슈팅 경험

프로젝트 진행 중 발생할 수 있는 일반적인 문제 상황과 해결 방안에 대한 경험을 기술합니다.

*   **문제:** 특정 시간대 응답 속도 저하 및 CPU 사용량 급증
    *   **진단:** Grafana 대시보드에서 Tomcat WAS의 Active Thread 수가 급증하고 GC 시간이 길어지는 것을 확인. Prometheus 쿼리를 통해 특정 API 엔드포인트의 Latency 증가 확인.
    *   **해결:** `docker-compose.yml`에서 Tomcat 컨테이너의 CPU/Memory Limit을 조정하여 자원을 추가 할당하고, Tomcat `server.xml`의 Executor(Thread Pool) 설정을 최적화하여 동시 요청 처리 능력 증대. 불필요한 GC 발생을 줄이기 위해 JVM 힙 사이즈 조정.
*   **문제:** Nginx 로드밸런싱 오류 (특정 WAS로만 트래픽 집중)
    *   **진단:** Nginx Access Log 및 Grafana의 Nginx Metrics 대시보드를 통해 특정 Tomcat 인스턴스로만 트래픽이 집중되는 것을 확인. Nginx `error.log`에서 WAS 인스턴스 연결 실패 오류 확인.
    *   **해결:** Nginx `upstream` 설정에서 `server` 지시어의 가중치(weight)가 기본값으로 설정되어 있는지 확인하고, WAS 컨테이너의 네트워크 연결 상태(`docker network inspect`) 및 포트 노출 상태를 점검.

이러한 경험을 통해 모니터링 데이터가 문제 해결의 핵심 단서를 제공하며, 시스템 전반의 상태를 종합적으로 이해하고 신속하게 대응하는 능력을 길렀습니다.

## 🤝 기여 (Contribution)

이 프로젝트는 개인 학습 및 포트폴리오 목적으로 진행되었으며, 추가적인 기여는 환영합니다.

## 📜 라이선스

이 프로젝트는 [적절한 라이선스 선택 (예: MIT License)]에 따라 배포됩니다.
#   s c a l a b l e - w a s - a r c h i t e c t u r e  
 