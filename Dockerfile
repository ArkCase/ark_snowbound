###########################################################################################################
#
# How to build:
#
# docker build -t 345280441424.dkr.ecr.ap-south-1.amazonaws.com/ark_snowbound:latest .
# docker push 345280441424.dkr.ecr.ap-south-1.amazonaws.com/ark_snowbound:latest
#
# How to run: (Helm)
#
# helm repo add arkcase https://arkcase.github.io/ark_snowbound/
# helm install ark-snowbound arkcase/ark-snowbound
# helm uninstall ark-snowbound
#
###########################################################################################################

FROM 345280441424.dkr.ecr.ap-south-1.amazonaws.com/ark_base:latest

LABEL ORG="Armedia LLC"
LABEL APP="Snowbound"
LABEL VERSION="1.1"
LABEL IMAGE_SOURCE="https://github.com/ArkCase/ark_snowbound"
LABEL MAINTAINER="Armedia DevOps Team <devops@armedia.com>"

# Variables: Versions
ARG SNOWBOUND_ARKCASE_VERSION="2021.02.04"
ARG SNOWBOUND_VERSION="5.6.2-$SNOWBOUND_ARKCASE_VERSION"
ARG TOMCAT_VERSION="9.0.50"
ARG TOMCAT_MAJOR_VERSION="9"

# Variables: Tarball stuff
ARG SNOWBOUND="VirtualViewerJavaHTML5-${SNOWBOUND_VERSION}"
ARG SNOWBOUND_WAR="VirtualViewerJavaHTML5-${SNOWBOUND_VERSION}.war"
ARG TOMCAT="apache-tomcat-${TOMCAT_VERSION}"
ARG TOMCAT_TARBALL="apache-tomcat-${TOMCAT_VERSION}.tar.gz"
ARG TOMCAT_TARBALL_SHA512="06cd51abbeebba9385f594ed092bd30e510b6314c90c421f4be5d8bec596c6a177785efc2ce27363813f6822af89fc88a2072d7b051960e5387130faf69c447b"

# Variables: Download URLs
ARG SNOWBOUND_URL="https://github.com/ArkCase/arkcase-dependencies/releases/download/${SNOWBOUND_ARKCASE_VERSION}/${SNOWBOUND_WAR}"
ARG TOMCAT_URL="https://archive.apache.org/dist/tomcat/tomcat-${TOMCAT_MAJOR_VERSION}/v${TOMCAT_VERSION}/bin/${TOMCAT_TARBALL}"

# Environment variables: Java & Tomcat stuff
ENV JRE_HOME=/usr/lib/jvm/jre-11-openjdk \
    CATALINA_HOME=/app/tomcat \
    CATALINA_PID=/app/tomcat/temp/tomcat.pid \
    CATALINA_OUT=/dev/stdout \
    CATALINA_TMPDIR=/app/tomcat/temp \
    JAVA_FONTS=/app/fonts/.fonts/ \
    TOMCAT_HTTP_PORT=8080 \
# Environment variables: System stuff
    PATH="/app/tomcat/bin:$PATH"

WORKDIR /app
ADD "${SNOWBOUND_URL}" "${TOMCAT_URL}" ./

COPY files/fonts.tar.gz \
    files/server.xml.j2 \
    files/web.xml \
    files/startup.sh \
    files/VirtualViewerJavaHTML5.xml ./

SHELL ["/bin/bash", "-c"]
RUN     set -eu -o pipefail; \
        checksum=$(sha512sum "$TOMCAT_TARBALL" | awk '{ print $1 }'); \
        if [ $checksum != "$TOMCAT_TARBALL_SHA512" ]; then \
            echo "Unexpected SHA512 checkum for Tomcat tarball; possible man-in-the-middle attack"; \
            exit 1; \
        fi; \
        yum --assumeyes update; \
        yum --assumeyes install java-11-openjdk unzip python3; \
        yum --assumeyes clean all; \
        pip3 install --no-cache-dir jinja2-cli; \
        # Unpack Tomcat into the `tomcat` directory
        tar xf "$TOMCAT_TARBALL"; \
        mv "$TOMCAT" tomcat; \
        rm "$TOMCAT_TARBALL"; \
        mv -f web.xml tomcat/conf/; \
        # `/bin/sh` removes env vars it doesn't support (i.e. the ones with periods in their names)
        # More information [here](https://github.com/docker-library/tomcat/issues/77)
        # Use `/bin/bash` instead
        find tomcat/bin/ -name '*.sh' -exec sed -ri 's|^#!/bin/sh$|#!/bin/bash|' '{}' +; \
        # Fix permissions (especially when running as non-root)
        # More information [here](https://github.com/docker-library/tomcat/issues/35)
        chmod -R +rX . ; \
        chmod 777 tomcat/work; \
        chmod u+x tomcat/bin/*.sh; \
        # Removal of default/unwanted Applications
        rm -rf tomcat/webapps/* tomcat/temp/* tomcat/logs tomcat/bin/*.bat; \
        # Create `tomcat` user
        useradd --system --user-group --no-create-home --home-dir /app/home tomcat; \
        # Install Snowbound
        mkdir -p home/.snowbound-docs fonts tomcat/webapps/VirtualViewerJavaHTML5 tomcat/conf/Catalina/localhost; \
        unzip -d tomcat/webapps/VirtualViewerJavaHTML5 "$SNOWBOUND_WAR"; \
        rm "$SNOWBOUND_WAR"; \
        # Install Snowbound configuration file
        chmod 644 VirtualViewerJavaHTML5.xml; \
        mv VirtualViewerJavaHTML5.xml tomcat/conf/Catalina/localhost/; \
        # Setup fonts
        tar xf fonts.tar.gz -C fonts; \
        rm fonts.tar.gz; \
        cd fonts; \
        fc-cache -f -v; \
        cd ..; \
        # Fix permissions
        chown -R tomcat:tomcat tomcat home; \
        # Remove unwanted packages, including `yum` itself
        yum --assumeyes erase unzip; \
        #rpm --erase --nodeps yum yum-plugin-fastestmirror yum-plugin-ovl yum-utils; \
        rm -rf /var/cache/yum

VOLUME /app/home/.snowbound-docs

EXPOSE 8080
USER tomcat
ENTRYPOINT ["/app/startup.sh"]
CMD ["run"]
