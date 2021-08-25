#!/bin/bash

jinja2 server.xml.j2 > tomcat/conf/server.xml

exec /app/tomcat/bin/catalina.sh "$@"
