## Prerequisites ##
# Deploy K8s Cluster from TFE - myorganization
# Deploy HashiStack Dev Cluster for Vault - rogmanster
# Export gcloud for kubectl commands
# Export VAULT_ADDR for Vault commands

###############################
## KUBERNETES CONFIGURATIONS ##
###############################
clear

## Kubectl apply service account
kubectl apply -f k8s/postgres-serviceaccount.yml
echo
read -p "press enter to continue..."
clear

########################
## POSTGRES CONTAINER ##
########################
clear

## Deploy postgres db container on kubernetes
kubectl apply -f k8s/postgres_kong.yaml
sleep 3
echo
read -p "press enter to continue..."

######################################
## VAULT AUTH ENGINE CONFIGURATIONS ##
######################################
## PERSONA - ADMIN
clear

## Set Vault Premium License
vault write sys/license text=$VAULT_PREMIUM_LICENSE

## Get variable inputs for Vault from K8s (SA Name, JWT, Certificate and K8s API endpoint)
export VAULT_SA_NAME=$(kubectl get sa postgres-vault -o jsonpath="{.secrets[*]['name']}")
export SA_JWT_TOKEN=$(kubectl get secret $VAULT_SA_NAME -o jsonpath="{.data.token}" | base64 --decode; echo)
export SA_CA_CRT=$(kubectl get secret $VAULT_SA_NAME -o jsonpath="{.data['ca\.crt']}" | base64 --decode; echo)
export K8s_HOST=$(kubectl config view | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}')

## Write and read Vault Kubernetes AUTH config
vault auth enable kubernetes
vault write auth/kubernetes/config \
  token_reviewer_jwt="$SA_JWT_TOKEN" \
  kubernetes_host="https://$K8s_HOST:443" \
  kubernetes_ca_cert="$SA_CA_CRT"

## Write and read Vault postgres policy
echo 'path "database/creds/readonly" {
  capabilities = ["read"]
}
path "sys/leases/renew" {
  capabilities = ["create"]
}
path "sys/leases/revoke" {
  capabilities = ["update"]
}' | vault policy write postgres-policy -

## Write and read Vault policy to role binding
vault write auth/kubernetes/role/postgres \
    bound_service_account_names=postgres-vault \
    bound_service_account_namespaces=default \
    policies=postgres-policy \
    ttl=24h

echo
read -p "press enter to continue..."


########################################
## VAULT SECRET ENGINE CONFIGURATIONS ##
########################################
## PERSONA - ADMIN
clear

## Set Postgres LoabBalancer IP
POSTGRES_IP=$(kubectl get svc | grep LoadBalancer | awk '{print $4}')

## Write and read postgres secret backend configuration
vault secrets enable database
vault write database/config/demo \
plugin_name=postgresql-database-plugin \
allowed_roles=readonly \
    connection_url=" user={{username}} password={{password}} \
    host=$POSTGRES_IP port=5432 dbname=demo sslmode=disable" \
    username="roger" \
    password="password123"

## Configure role configuration for postgres
vault write database/roles/readonly db_name=demo \
creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; GRANT SELECT ON ALL TABLES IN SCHEMA public TO \"{{name}}\";" \
default_ttl=1h max_ttl=90

echo
read -p "press enter to continue..."

#########################################
## KUBERNETES CLIENT CONTAINER TESTING ##
#########################################
## PERSONA - APP
clear

## The below will deploy the vaul-sidecar which will authenticate to K8s
## and inject the token into the container and store it on a volume reachable
## by the container /home/vault/.vault-home
## https://github.com/sethvargo/vault-kubernetes-authenticator

envsubst < ~/projects/vault/k8s/vault_k8s_init.yaml | kubectl apply -f -
sleep 5
kubectl exec -it vault-sidecar /bin/sh

## Curl command to run inside the container to fetch postgres cred
curl --header "X-Vault-Token: $(cat ~/.vault-token)" $VAULT_ADDR/v1/database/creds/readonly
