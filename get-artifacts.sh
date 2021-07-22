#!/bin/bash

set -eu -o pipefail

here=$(realpath "$0")
here=$(dirname "$here")
cd "$here"

snowbound_version="5.6.2-2021.02.04"
snowbound="VirtualViewerJavaHTML5-${snowbound_version}.war"

#XXX
#jmx_prometheus_agent_version="0.15.0"
#jmx_prometheus_agent="jmx_prometheus_javaagent-${jmx_prometheus_agent_version}"

rm -rf artifacts
mkdir artifacts

echo "Downloading $snowbound"
aws s3 cp "s3://arkcase-container-artifacts/ark_snowbound/artifacts/${snowbound}" artifacts/

#XXX
#echo "Downloading $jmx_prometheus_agent"
#aws s3 cp "s3://arkcase-container-artifacts/ark_activemq/${jmx_prometheus_agent}.jar" artifacts/
