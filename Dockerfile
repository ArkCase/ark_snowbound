# NB: Our `base_centos` image is a pure copy of the `centos` image available on
#     Docker hub. More information available
#     [here](https://arkcase.atlassian.net/wiki/spaces/AANTA/pages/1558446081/Process+for+updating+our+base+image+base+centos).
FROM 345280441424.dkr.ecr.ap-south-1.amazonaws.com/base_centos:7-20210630

LABEL ORG="Armedia LLC"
LABEL APP="Snowbound"
LABEL VERSION="1.0"
LABEL IMAGE_SOURCE="https://github.com/ArkCase/ark_snowbound"
LABEL MAINTAINER="Armedia LLC"

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
# Environment variables: System stuff
    PATH="/app/tomcat/bin:$PATH"

WORKDIR /app
ADD "${SNOWBOUND_URL}" "${TOMCAT_URL}" ./

COPY fonts.tar.gz VirtualViewerJavaHTML5.xml ./

RUN     set -eu; \
        checksum=$(sha512sum "$TOMCAT_TARBALL" | awk '{ print $1 }'); \
        if [ $checksum != $TOMCAT_TARBALL_SHA512 ]; then \
            echo "Unexpected SHA512 checkum for Tomcat tarball; possible man-in-the-middle attack"; \
            exit 1; \
        fi; \
        yum --assumeyes update; \
        yum --assumeyes install java-11-openjdk unzip; \
        yum --assumeyes clean all; \
        tar xf "$TOMCAT_TARBALL"; \
        rm "$TOMCAT_TARBALL"; \
        ln -s "$TOMCAT" tomcat; \
        rm -rf tomcat/webapps/* tomcat/temp/* tomcat/logs; \
        useradd --system --user-group --no-create-home --home-dir /app/home tomcat; \
        mkdir -p home fonts tomcat/webapps/VirtualViewerJavaHTML5 tomcat/conf/Catalina/localhost snowbound-docs; \
        ln -s /app/snowbound-docs /app/home/.snowbound-docs; \
        unzip -d tomcat/webapps/VirtualViewerJavaHTML5 "$SNOWBOUND_WAR"; \
        rm "$SNOWBOUND_WAR"; \
        chmod 644 VirtualViewerJavaHTML5.xml; \
        mv VirtualViewerJavaHTML5.xml tomcat/conf/Catalina/localhost/; \
        tar xf fonts.tar.gz -C fonts; \
        rm fonts.tar.gz; \
        cd fonts; \
        fc-cache -f -v; \
        cd ..; \
        chown -R tomcat:tomcat "$TOMCAT" home snowbound-docs; \
        yum --assumeyes erase unzip; \
        rpm --erase --nodeps yum; \
        rm -rf /var/cache/yum

VOLUME /app/snowbound-docs

EXPOSE 8080
USER tomcat
ENTRYPOINT ["/app/tomcat/bin/catalina.sh"]
CMD ["run"]
