#!/bin/bash

# NB: The latest version of Snowbound is available
#     [here](https://github.com/ArkCase/arkcase-dependencies/releases). Please
#     note we modify the vanilla release from Snowbound Software and customize
#     it for ArkCase's needs. Please contact Bojan Milenkoski for more
#     information.
#
# NB: The version of Tomcat that is used here has been downloaded from [the Apache
#     archive](https://archive.apache.org/dist/tomcat/tomcat-9/v9.0.50/bin/apache-tomcat-9.0.50.tar.gz).

set -eu -o pipefail

here=$(realpath "$0")
here=$(dirname "$here")
cd "$here"

snowbound_version="5.6.2-2021.02.04"
snowbound_war="VirtualViewerJavaHTML5-${snowbound_version}.war"
tomcat_version="9.0.50"
tomcat_major_version="9"
tomcat_tarball="apache-tomcat-${tomcat_version}.tar.gz"

#XXX
#jmx_prometheus_agent_version="0.15.0"
#jmx_prometheus_agent="jmx_prometheus_javaagent-${jmx_prometheus_agent_version}"

#rm -rf artifacts
#mkdir artifacts
#
#echo "Downloading $snowbound_war"
#aws s3 cp "s3://arkcase-container-artifacts/ark_snowbound/artifacts/${snowbound_war}" artifacts/

echo "Downloading $tomcat_tarball"
aws s3 cp "s3://arkcase-container-artifacts/ark_snowbound/artifacts/${tomcat_tarball}" artifacts/

#XXX
#echo "Downloading $jmx_prometheus_agent"
#aws s3 cp "s3://arkcase-container-artifacts/ark_activemq/${jmx_prometheus_agent}.jar" artifacts/
