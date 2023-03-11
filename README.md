# Snowbound for ArkCase

## How to build:

docker build -t ${BASE\_REGISTRY}/arkcase/snowbound:latest .

docker push ${BASE\_REGISTRY}/arkcase/snowbound:latest

## How to run: (Helm)

helm repo add arkcase https://arkcase.github.io/ark\_helm\_charts/

helm install snowbound ark-snowbound

helm uninstall snowbound
