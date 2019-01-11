## Consul Server Configuration Demo
# Consul-Template with Vault Integration
# export VAULT_ADDR='http://localhost:8200'

##CONSUL KV & POLICY CONFIGURATION
# Create Consul KV Entry
curl  \
  --header "X-Consul-Token: root" \
  --request PUT \
  --data '{"myConfig":"hello consul"}' \
    http://127.0.0.1:8500/v1/kv/myserver

# Create Consul Policy
curl \
    --header "X-Consul-Token: root" \
    --request PUT \
    --data '{
      "Name": "myserver-policy",
      "Description": "Grant read access to KV",
      "Rules": "key_prefix \"myserver\" { policy =\"read\"}",
      "Datacenters": ["dc1"] }' \
    http://127.0.0.1:8500/v1/acl/policy

echo
read -p "press enter to continue..."
clear

## VAULT CONSUL SECRET ENGINE
# Configure Vault
vault secrets enable consul
vault write consul/config/access \
    address=127.0.0.1:8500 \
    token=root

# Tie Vault role to Consul policy
vault write consul/roles/my-role \
    policy=$(base64 <<< 'key "" { policy = "read" }')

echo
read -p "press enter to continue..."
clear

## VAULT USERPASS AUTH
# Create policy to read credentials
# capabilities = ["create", "read", "update", "delete", "list"]
echo 'path "/consul/creds/my-role" {
    capabilities = ["list","read"]
}' | vault policy write my-policy -

# Create userpass account
vault auth enable userpass
vault write auth/userpass/users/roger password=password123 policies=my-policy

## CONSUL-TEMPLATE CONFIGURATION
# Authenticate with Vault
VAULT_MGMT_TOKEN=$(curl \
    --request POST \
    --data '{"password": "password123"}' \
    $VAULT_ADDR/v1/auth/userpass/login/roger | jq -r '.auth.client_token')

# Fetch dynamically created Consul token from Vault
CONSUL_TOKEN=$(curl \
    --header "X-Vault-Token: ${VAULT_MGMT_TOKEN}" \
    http://127.0.0.1:8200/v1/consul/creds/my-role | jq -r '.data.token')

# Create Consul-Template configuration
tee > consul.hcl <<CONFIG
consul {
  address = "127.0.0.1:8500"
  token = "${CONSUL_TOKEN}"
}
vault {
    renew_token = false
}
CONFIG

# Create Consul-Template template
tee > in.tpl <<KV
{{ key "myserver" }}
KV
echo
read -p "press enter to continue..."
clear

## CONSUL-TEMPLATE OUTPUT
# Run Consul-Template (note: will run as daemon unless '-once' is used)
consul-template  -config=consul.hcl  -template "in.tpl:out.txt" &

# show output of Consul-Template file
sleep 1
echo
ls -l
echo
echo "tail 'out.txt. for 30 seconds...'"
gtimeout 30s tail -F out.txt

echo
read -p "press enter to clean up..."
clear

rm consul.hcl
rm in.tpl
rm out.txt
