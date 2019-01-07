##LDAP Auth + Dynamic AD Secret Generation

##Prerequisites
#Deploy Vault Instance and export VAULT_ADDR
#Configure Windows AD Configuration
#Set AD Accounts - ssp.admin, pacman.admin

##VAULT LDAP AUTH CONFIGURATIONS
#Set Vault Premium License
clear
vault login root
vault write sys/license text=$VAULT_PREMIUM_LICENSE

#Enable and configure LDAP Auth plugin
vault auth enable ldap

vault write auth/ldap/config \
    url=ldap://10.0.0.251:389 \
    binddn=ssp.admin \
    bindpass=hashi123! \
    userdn=CN=Users,DC=roger,DC=local \
    userattr=CN \
    groupdn=CN=Users,DC=roger,DC=local \
    groupattr=CN \
    insecure_tls=true

#Vault policy read AD dynamic secret for pacman
echo 'path "domain1/*" {
  capabilities = ["read","list"]
}
path "sys/leases/renew" {
  capabilities = ["create"]
}
path "sys/leases/revoke" {
  capabilities = ["update"]
}' | vault policy write domain1-policy -

#Tie LDAP group to Vault policy
vault write auth/ldap/groups/"Domain Admins" policies=kv-policy,domain1-policy

echo
read -p "press enter to continue..."
clear

## VAULT SECRET ENGINE CONFIGURATIONS
# Configure AD Secret Engine using pacman path
vault secrets enable -path=domain1 ad
vault write domain1/config \
  binddn=ssp.admin  \
  bindpass=hashi123! \
  url=ldaps://10.0.0.251:636 \
  userdn=dc=roger,dc=local  \
  insecure_tls=true

#Configure role configuration for Windows AD
vault write domain1/roles/pacman.admin \
  service_account_name=pacman.admin@roger.local \
  ttl=60s

vault write domain1/roles/galaga.admin \
  service_account_name=galaga.admin@roger.local \
  ttl=60s

echo
read -p "press enter to continue..."
clear

##Output of Vault Token using LDAP Auth..."
curl \
    --request POST \
    --data '{"password": "hashi123!"}' \
    $VAULT_ADDR/v1/auth/ldap/login/ssp.admin | jq
echo
read -p "press enter to continue..."
clear

#Set Vault Token to Variable
TOKEN=$(curl \
    --request POST \
    --data '{"password": "hashi123!"}' \
    $VAULT_ADDR/v1/auth/ldap/login/ssp.admin | jq -r '.auth.client_token')
echo
read -p "press enter to continue..."
clear

#Fetch AD Dynamic Secret
curl \
    --header "X-Vault-Token: $TOKEN" \
    $VAULT_ADDR/v1/domain1/creds/pacman.admin | jq

curl \
    --header "X-Vault-Token: $TOKEN" \
    $VAULT_ADDR/v1/domain1/creds/galaga.admin | jq

# vault login -method=ldap username=ssp.admin
# vault read pacman/creds/pacman.admin
# vault read pacman/roles/pacman.admin
# vault read secret/data/mycred
# ldapsearch -x -D "CN=pacman.admin,CN=Users,DC=roger,DC=local" -W -H ldap://10.0.0.251 -b "CN=Users,DC=roger,DC=local" \ -s sub ‘galaga.admin’

