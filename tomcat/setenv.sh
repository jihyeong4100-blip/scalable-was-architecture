#!/bin/sh
CATALINA_OPTS="$CATALINA_OPTS -javaagent:/usr/local/tomcat/lib/jmx_prometheus_javaagent.jar=${JMX_PORT}:/usr/local/tomcat/conf/jmx_exporter_config.yml"
