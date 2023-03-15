#!/bin/bash
set -euo pipefail

[ -v BASE_DIR ] || BASE_DIR="/app"
[ -v CATALINA_HOME ] || CATALINA_HOME="${BASE_DIR}/tomcat"
[ -v APP_USER ] || APP_USER="$(id -un)"
[ -v HOME_DIR ] || HOME_DIR="${BASE_DIR}/${APP_USER}"
[ -v LOGS_DIR ] || LOGS_DIR="${HOME_DIR}/logs"

[ ${#} -gt 0 ] || set -- "run"

[ -v CATALINA_OPTS ] || CATALINA_OPTS=""
CATALINA_OPTS+=" -Dlogs.dir='${LOGS_DIR}'"
export CATALINA_OPTS

exec "${CATALINA_HOME}/bin/catalina.sh" "$@"
