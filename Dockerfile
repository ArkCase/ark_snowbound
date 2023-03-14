###########################################################################################################
#
# How to build:
#
# docker build -t ${BASE_REGISTRY}/arkcase/snowbound:latest .
# docker push ${BASE_REGISTRY}/arkcase/snowbound:latest
#
# How to run: (Helm)
#
# helm repo add arkcase https://arkcase.github.io/ark_snowbound/
# helm install ark-snowbound arkcase/ark-snowbound
# helm uninstall ark-snowbound
#
###########################################################################################################

ARG BASE_REGISTRY
ARG BASE_REPO="arkcase/base"
ARG BASE_TAG="8.7.0"

FROM "${BASE_REGISTRY}/${BASE_REPO}:${BASE_TAG}"

# Variables: Versions
ARG SNOWBOUND_ARKCASE_VERSION="2021.03"
ARG SNOWBOUND_VERSION="5.6.2-${SNOWBOUND_ARKCASE_VERSION}"
ARG TOMCAT_VERSION="9.0.50"
ARG TOMCAT_MAJOR_VERSION="9"
ARG VER="${SNOWBOUND_VERSION}"
ARG BASE_DIR="/app"
ARG APP_USER="snowbound"
ARG APP_UID="1000"
ARG APP_GROUP="${APP_USER}"
ARG APP_GID="${APP_UID}"
ARG HOME_DIR="${BASE_DIR}/${APP_USER}"
ARG LOGS_DIR="${HOME_DIR}/logs"
ARG TEMP_DIR="${HOME_DIR}/temp"
ARG WORK_DIR="${HOME_DIR}/work"

# Variables: Tarball stuff
ARG SNOWBOUND="VirtualViewerJavaHTML5-${SNOWBOUND_VERSION}"
ARG SNOWBOUND_WAR="VirtualViewerJavaHTML5-${SNOWBOUND_VERSION}.war"
ARG TOMCAT="apache-tomcat-${TOMCAT_VERSION}"
ARG TOMCAT_TARBALL="apache-tomcat-${TOMCAT_VERSION}.tar.gz"
ARG TOMCAT_TARBALL_SHA512="06cd51abbeebba9385f594ed092bd30e510b6314c90c421f4be5d8bec596c6a177785efc2ce27363813f6822af89fc88a2072d7b051960e5387130faf69c447b"

# Variables: Download URLs
ARG SNOWBOUND_URL="https://github.com/ArkCase/arkcase-dependencies/releases/download/${SNOWBOUND_ARKCASE_VERSION}/${SNOWBOUND_WAR}"
ARG TOMCAT_URL="https://archive.apache.org/dist/tomcat/tomcat-${TOMCAT_MAJOR_VERSION}/v${TOMCAT_VERSION}/bin/${TOMCAT_TARBALL}"

LABEL ORG="Armedia LLC"
LABEL APP="Snowbound"
LABEL VERSION="${SNOWBOUND_VERSION}"
LABEL IMAGE_SOURCE="https://github.com/ArkCase/ark_snowbound"
LABEL MAINTAINER="Armedia DevOps Team <devops@armedia.com>"

# Environment variables: Java & Tomcat stuff
ENV JRE_HOME="/usr/lib/jvm/jre-11-openjdk" \
    CATALINA_HOME="/app/tomcat" \
    CATALINA_PID="${CATALINA_HOME}/tomcat.pid" \
    CATALINA_OUT="/dev/stdout" \
    CATALINA_TMPDIR="${TEMP_DIR}" \
    TEMP="${TEMP_DIR}" \
    TMP="${TEMP_DIR}" \
    JAVA_FONTS="/app/fonts/.fonts/" \
    PATH="${CATALINA_HOME}/bin:$PATH" \
    APP_USER="${APP_USER}" \
    HOME_DIR="${HOME_DIR}" \
    LOGS_DIR="${LOGS_DIR}" \
    WORK_DIR="${WORK_DIR}" \
    TEMP_DIR="${TEMP_DIR}"

WORKDIR "${BASE_DIR}"
ADD "${SNOWBOUND_URL}" "${TOMCAT_URL}" ./

COPY files/* ./

SHELL ["/bin/bash", "-c"]
RUN     set -eu -o pipefail; \
        checksum=$(sha512sum "$TOMCAT_TARBALL" | awk '{ print $1 }'); \
        if [ $checksum != "$TOMCAT_TARBALL_SHA512" ]; then \
            echo "Unexpected SHA512 checkum for Tomcat tarball; possible man-in-the-middle attack"; \
            exit 1; \
        fi; \
        yum -y update; \
        yum -y install java-11-openjdk unzip; \
        yum -y clean all; \
        # Unpack Tomcat into the `tomcat` directory
        tar xf "${TOMCAT_TARBALL}"; \
        mv "${TOMCAT}" "${CATALINA_HOME}"; \
        rm "${TOMCAT_TARBALL}"; \
        mv -f logging.properties "${CATALINA_HOME}/conf"; \
        mv -f server.xml "${CATALINA_HOME}/conf"; \
        mv -f web.xml "${CATALINA_HOME}/conf"; \
        # `/bin/sh` removes env vars it doesn't support (i.e. the ones with periods in their names)
        # More information [here](https://github.com/docker-library/tomcat/issues/77)
        # Use `/bin/bash` instead
        find "${CATALINA_HOME}/bin" -name '*.sh' -exec sed -ri 's|^#!/bin/sh$|#!/bin/bash|' '{}' +; \
        # Fix permissions (especially when running as non-root)
        # More information [here](https://github.com/docker-library/tomcat/issues/35)
        chmod -R +rX . ; \
        chmod u+x "${CATALINA_HOME}/bin"/*.sh; \
        # Removal of default/unwanted Applications
        rm -rf "${CATALINA_HOME}/webapps"/* "${CATALINA_HOME}"/{temp,work,logs} "${CATALINA_HOME}/bin"/*.bat; \
        # Create `tomcat` user
        groupadd --system --gid "${APP_GID}" "${APP_GROUP}"; \
        useradd --system --no-user-group --gid "${APP_GROUP}" --no-create-home --home-dir "${HOME_DIR}" --uid "${APP_UID}" "${APP_USER}"; \
        # Install Snowbound
        mkdir -p "${HOME_DIR}/.snowbound-docs" fonts "${CATALINA_HOME}/webapps/VirtualViewerJavaHTML5" "${CATALINA_HOME}/conf/Catalina/localhost" "${TEMP_DIR}" "${WORK_DIR}" "${LOGS_DIR}"; \
        unzip -d "${CATALINA_HOME}/webapps/VirtualViewerJavaHTML5" "${SNOWBOUND_WAR}"; \
        rm "${SNOWBOUND_WAR}"; \
        # Install Snowbound configuration file
        chmod 644 VirtualViewerJavaHTML5.xml; \
        mv VirtualViewerJavaHTML5.xml "${CATALINA_HOME}/conf/Catalina/localhost"; \
        # Setup fonts
        tar xf fonts.tar.gz -C fonts; \
        rm fonts.tar.gz; \
        ( cd fonts && fc-cache -f -v ) ; \
        # Fix permissions
        chown -R "${APP_USER}:${APP_GROUP}" "${CATALINA_HOME}" "${HOME_DIR}"; \
        chmod -R ug=rwX,o=rX "${HOME_DIR}";

VOLUME [ "${HOME_DIR}" ]

EXPOSE 8080
USER tomcat
ENTRYPOINT ["/app/startup.sh"]
CMD ["run"]
