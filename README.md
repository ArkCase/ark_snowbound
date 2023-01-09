# ark_snowbound

## How to build:

docker build -t 345280441424.dkr.ecr.ap-south-1.amazonaws.com/ark_snowbound:latest .

docker push 345280441424.dkr.ecr.ap-south-1.amazonaws.com/ark_snowbound:latest

## How to run: (Helm)

helm repo add arkcase https://arkcase.github.io/ark_snowbound/

helm install ark-snowbound arkcase/ark-snowbound

helm uninstall ark-snowbound
