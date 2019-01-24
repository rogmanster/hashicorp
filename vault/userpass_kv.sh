## Userpass Auth + KV Secret

## Prerequisites
# Deploy Vault Instance and export VAULT_ADDR

#############################
## VAULT KV Secret Config  ##
#############################
#Set Vault Premium License
clear
vault login root
vault write sys/license text=$VAULT_PREMIUM_LICENSE

#Write arbitrary secret to KV
vault kv put secret/mycred username=milli password=vanilli

## Write Vault policy
#capabilities = ["create", "read", "update", "delete", "list"]
echo 'path "secret/metadata/" {
    capabilities = ["list"]
}

path "secret/data/mycred" {
    capabilities = ["read"]
}' | vault policy write my-policy -

echo
read -p "press enter to continue..."
clear

#################################
## VAULT Userpass Auth Config  ##
#################################
#Enable auth method
vault auth enable userpass

#Create user and password
vault write auth/userpass/users/roger password=password123 policies=my-policy

echo
read -p "press enter to continue..."
clear

#####################
## Fetch KV Secret ##
#####################

curl \
    --request POST \
    --data '{"password": "password123"}' \
$VAULT_ADDR/v1/auth/userpass/login/roger | jq

echo
read -p "press enter to continue..."
clear

TOKEN=$(curl \
    --request POST \
    --data '{"password": "password123"}' \
$VAULT_ADDR/v1/auth/userpass/login/roger | jq -r '.auth.client_token')

curl \
    --header "X-Vault-Token: $TOKEN" \
    $VAULT_ADDR/v1/secret/data/mycred | jq

#vault login -method=userpass username=roger
#vault kv get secret/mycred
