FROM tomcat:9.0-jdk11-openjdk

COPY ./your-app.war /usr/local/tomcat/webapps/

# Update apt and install dependencies
RUN set -ex; \
    export DEBIAN_FRONTEND=noninteractive; \
    apt-get update && \
    apt-get install -y wget ca-certificates

# Download JMX Exporter
RUN set -ex; \
    wget -O /usr/local/tomcat/lib/jmx_prometheus_javaagent.jar \
    https://repo1.maven.org/maven2/io/prometheus/jmx/jmx_prometheus_javaagent/0.17.2/jmx_prometheus_javaagent-0.17.2.jar

# Clean up apt cache
RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# JMX Exporter 설정 파일 복사
COPY ./jmx_exporter_config.yml /usr/local/tomcat/conf/jmx_exporter_config.yml

# CATALINA_OPTS에 JMX Exporter 추가
ENV CATALINA_OPTS="-javaagent:/usr/local/tomcat/lib/jmx_prometheus_javaagent.jar=${JMX_PORT}:/usr/local/tomcat/conf/jmx_exporter_config.yml"

EXPOSE 8080
# JMX Exporter 포트
EXPOSE 9010
