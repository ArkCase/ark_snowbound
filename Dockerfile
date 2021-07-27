# NB: Our `base_centos` image is a pure copy of the `centos` image available on
#     Docker hub. More information available
#     [here](https://arkcase.atlassian.net/wiki/spaces/AANTA/pages/1558446081/Process+for+updating+our+base+image+base+centos).
FROM 345280441424.dkr.ecr.ap-south-1.amazonaws.com/base_centos:7-20210630

LABEL   ORG="Armedia LLC" \
        APP="Snowbound" \
        VERSION="1.0" \
        IMAGE_SOURCE="https://github.com/ArkCase/ark_snowbound" \
        MAINTAINER="Armedia LLC"

# Environment variables: versions
ENV SNOWBOUND_VERSION="5.6.2-2021.02.04" \
    TOMCAT_VERSION="9.0.50" \
    TOMCAT_MAJOR_VERSION="9"

# Environment variables: Tarball stuff
ENV SNOWBOUND="VirtualViewerJavaHTML5-$SNOWBOUND_VERSION" \
    SNOWBOUND_WAR="VirtualViewerJavaHTML5-$SNOWBOUND_VERSION.war" \
    TOMCAT="apache-tomcat-${TOMCAT_VERSION}" \
    TOMCAT_TARBALL="apache-tomcat-${TOMCAT_VERSION}.tar.gz" \
    TOMCAT_TARBALL_SHA512="06cd51abbeebba9385f594ed092bd30e510b6314c90c421f4be5d8bec596c6a177785efc2ce27363813f6822af89fc88a2072d7b051960e5387130faf69c447b" \
# Environment variables: Java & Tomcat stuff
    JAVA_HOME=/usr/lib/jvm/jre-11-openjdk \
    CATALINA_HOME=/app/tomcat \
    CATALINA_PID=/app/tomcat/temp/tomcat.pid \
    CATALINA_OUT=/dev/stdout \
    CATALINA_TMPDIR=/app/tomcat/temp \
# Environment variables: System stuff
    PATH="/app/tomcat/bin:$PATH"

WORKDIR /app
COPY "artifacts/${SNOWBOUND_WAR}" \
    "artifacts/${TOMCAT_TARBALL}" \
    ./

RUN     set -eu; \
        checksum=$(sha512sum "${TOMCAT_TARBALL}" | awk '{ print $1 }'); \
        if [ $checksum != $TOMCAT_TARBALL_SHA512 ]; then \
            echo "Unexpected SHA512 checkum for Tomcat tarball; possible man-in-the-middle attack"; \
            exit 1; \
        fi; \
        yum -y update; \
        yum -y install java-11-openjdk; \
        yum clean all; \
        tar xf "${TOMCAT_TARBALL}"; \
        rm "${TOMCAT_TARBALL}"; \
        ln -s "$TOMCAT" tomcat; \
        rm -rf tomcat/webapps/* tomcat/temp/* tomcat/logs; \
        useradd --system --user-group --no-create-home --home-dir /app/home tomcat; \
        chown -R tomcat:tomcat "$TOMCAT"; \
        ls -lA /app/tomcat/bin

EXPOSE 8080
USER tomcat
CMD ["/app/tomcat/bin/catalina.sh", "run"]
