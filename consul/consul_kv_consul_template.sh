## Consul and Consul-Template Demo Script
# Consul-Template Integration

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

# Create token (don't need for Vault Integration)
TOKEN=$(curl \
      --header "X-Consul-Token: root" \
      --request PUT \
      --data '{
         "Description": "Agent token for myserver-policy",
         "Policies": [
            {
               "Name": "myserver-policy"
            }
         ],
         "Local": false }' \
      http://127.0.0.1:8500/v1/acl/token | jq '.SecretID')

echo
read -p "press enter to continue..."
clear

## CONSUL-TEMPLATE CONFIGURATION
# Create Consul-Template configuration
tee > consul.hcl <<CONFIG
consul {
  address = "127.0.0.1:8500"
  token = ${TOKEN}
}
vault {
    renew_token = false
}
CONFIG

# Create Consul-Template template
tee > in.tpl <<KV
{{ key "myserver" }}
KV

## CONSUL-TEMPLATE OUTPUT
# Run Consul-Template (note: to not run as daemon use '-once')
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
