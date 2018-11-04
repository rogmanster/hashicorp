## Prerequisites ##
# Deploy K8s Cluster from TFE - myorganization
# Deploy HashiStack Dev Cluster for Vault - rogmanster
# Export gcloud for kubectl commands
# Export VAULT_ADDR for Vault commands
# Need

###############################
## KUBERNETES CONFIGURATIONS ##
###############################

# Create service account yaml
echo
echo "KUBERNETES CONFIGURATIONS"
echo
echo "Create k8s service account with role token-review-binding..."
echo
# Kubectl apply service account
kubectl apply -f k8s/postgres-serviceaccount.yml
clear

########################
## POSTGRES CONTAINER ##
########################

# Deploy postgres docker container
echo
echo "Kubernetes Postgres Service Account created - COMPLETE!"
echo
read -p "press enter to continue..."

# Deploy postgres db container on kubernetes
echo
echo "Deploying Postgres container on Kubernetes..."
echo

kubectl apply -f k8s/postgres_kong.yaml
sleep 3

echo
read -p "press enter to continue..."
echo

# Print external Postgres address for PSQL Admin connectivity
echo
echo "The Postgres LoadBalancer Address is: "
echo $(kubectl get svc | grep LoadBalancer | awk '{print $4}')
echo
echo "Postgres deployment - COMPLETE!"
echo
read -p "press enter to continue..."
clear

######################################
## VAULT AUTH ENGINE CONFIGURATIONS ##
######################################

echo
echo "VAULT CONFIGURATIONS - KUBERNETES AUTH ENGINE"
echo
echo "PERSONA - ADMIN"

## Set Vault Premium License
vault write sys/license text=$VAULT_PREMIUM_LICENSE

# Get variable inputs for Vault from K8s (SA Name, JWT, Certificate and K8s API endpoint)
export VAULT_SA_NAME=$(kubectl get sa postgres-vault -o jsonpath="{.secrets[*]['name']}")
export SA_JWT_TOKEN=$(kubectl get secret $VAULT_SA_NAME -o jsonpath="{.data.token}" | base64 --decode; echo)
export SA_CA_CRT=$(kubectl get secret $VAULT_SA_NAME -o jsonpath="{.data['ca\.crt']}" | base64 --decode; echo)
export K8s_HOST=$(kubectl config view | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}')

echo
echo "Configure Vault Kubernetes Authentication Engine..."

vault auth enable kubernetes
vault write auth/kubernetes/config \
  token_reviewer_jwt="$SA_JWT_TOKEN" \
  kubernetes_host="https://$K8s_HOST:443" \
  kubernetes_ca_cert="$SA_CA_CRT"

echo
echo "Configure Vault Postgres policy..."

cat > k8s/postgres-policy.hcl <<EOF
path "database/creds/readonly" {
  capabilities = ["read"]
}
path "sys/leases/renew" {
  capabilities = ["create"]
}
path "sys/leases/revoke" {
  capabilities = ["update"]
}
EOF

vault policy write postgres-policy k8s/postgres-policy.hcl

echo
echo "Bind role to Postgres policy..."

vault write auth/kubernetes/role/postgres \
    bound_service_account_names=postgres-vault \
    bound_service_account_namespaces=default \
    policies=postgres-policy \
    ttl=24h

echo
echo "Vault Kubernetes authentication engine configuration - COMPLETE!"
echo
read -p "press enter to continue..."
echo
clear

########################################
## VAULT SECRET ENGINE CONFIGURATIONS ##
########################################

echo
echo "VAULT CONFIGURATIONS - POSTGRES DATABASE ENGINE"
echo
echo "PERSONA - ADMIN"
echo
echo "Configure Vault Postgres database plugin..."
echo

# Set Postgres LoabBalancer IP
POSTGRES_IP=$(kubectl get svc | grep LoadBalancer | awk '{print $4}')

# Postgresql secret backend configuration
vault secrets enable database
vault write database/config/demo \
plugin_name=postgresql-database-plugin \
allowed_roles=readonly \
    connection_url="user=roger password=password123 \
    host=$POSTGRES_IP port=5432 dbname=demo sslmode=disable"

echo
echo "Configure role for postgres database access..."
echo

# Readonly role configuration for postgres db
vault write database/roles/readonly db_name=demo \
creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; GRANT SELECT ON ALL TABLES IN SCHEMA public TO \"{{name}}\";" \
default_ttl=1h max_ttl=24h

echo
echo "Vault postgres database secret engine configuration - COMPLETE!"
echo
read -p "press enter to continue..."
echo
clear

#########################################
## KUBERNETES CLIENT CONTAINER TESTING ##
#########################################

echo
echo "KUBERNETES CLIENT CONFIGURATION - AUTHENTICATE & SECRET RETRIEVAL"
echo
echo "PERSONA - APP"
echo
echo "Authenticating with K8s pod with Vault..."
echo

kubectl run client --rm -i --tty --serviceaccount=postgres-vault --env=VAULT_ADDR=$VAULT_ADDR --image alpine

apk update
apk add curl postgresql-client jq
KUBE_TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
VAULT_K8S_LOGIN=$(curl --request POST --data '{"jwt": "'"$KUBE_TOKEN"'", "role": "postgres"}' $VAULT_ADDR/v1/auth/kubernetes/login)
X_VAULT_TOKEN=$(echo $VAULT_K8S_LOGIN | jq -r '.auth.client_token')
POSTGRES_CREDS=$(curl --header "X-Vault-Token: $X_VAULT_TOKEN" $VAULT_ADDR/v1/database/creds/readonly)

echo $KUBE_TOKEN
echo $VAULT_K8S_LOGIN | jq
echo $X_VAULT_TOKEN
echo $POSTGRES_CREDS | jq
