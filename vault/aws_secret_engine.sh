## Userpass Auth + Dynamic AWS Secret Generation

## Prerequisites
# Deploy Vault Instance and export VAULT_ADDR
# Configure AWS Secret Engine
# Create userpass for authentication

########################################
## VAULT USERPASS AUTH CONFIGURATIONS ##
########################################
## PERSONA - ADMIN
## Set Vault Premium License
clear
vault login root
vault write sys/license text=$VAULT_PREMIUM_LICENSE

## Vault userpass configuration for 'roger'
vault auth enable userpass
vault write auth/userpass/users/roger password=password123 policies=my-policy,aws-policy
echo
read -p "press enter to continue..."
clear

############################################
## VAULT AWS SECRET ENGINE CONFIGURATIONS ##
############################################
## PERSONA - ADMIN
## Write and read Vault AWS Secret Engine policy
echo 'path "echo 'path "aws/*" {
  capabilities = ["read","list"]
}
path "sys/leases/renew" {
  capabilities = ["create"]
}
path "sys/leases/revoke" {
  capabilities = ["update"]
}' | vault policy write aws-policy -
echo
read -p "press enter to continue..."
clear

## Configure Vault AWS secrets engine
vault secrets enable -path=aws aws
vault write aws/config/root \
   access_key="$AWS_ACCESS_KEY_ID" \
   secret_key="$AWS_SECRET_ACCESS_KEY" \
   region=us-west-2

## Configure Vault lease
vault write aws/config/lease \
   lease=90s \
   lease_max=5m

## Configure Vault role and bind AWS Policy
vault write aws/roles/my-role \
    credential_type=iam_user \
    policy_document=-<<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Stmt1426528957000",
      "Effect": "Allow",
      "Action": [
        "ec2:*"
      ],
      "Resource": [
        "*"
      ]
    }
  ]
}
EOF
echo
read -p "press enter to continue..."
clear

## Output of Vault Token using Userpass Auth..."
curl \
    --request POST \
    --data '{"password": "password123"}' \
$VAULT_ADDR/v1/auth/userpass/login/roger | jq
echo
read -p "press enter to continue..."
clear

## Set Vault Token to Variable
TOKEN=$(curl \
    --request POST \
    --data '{"password": "password123"}' \
$VAULT_ADDR/v1/auth/userpass/login/roger | jq -r '.auth.client_token')
echo
read -p "press enter to continue..."
clear

## Fetch AWS Dynamic Secret
curl \
    --header "X-Vault-Token: $TOKEN" \
    $VAULT_ADDR/v1/aws/creds/my-role | jq
echo
read -p "press enter to continue..."
clear

## Optional Vault CLI Commands
# vault login -method=userpass username=roger
# vault read aws/creds/my-role
# vault lease revoke aws/creds/my-role/<lease id>
# vault read aws/creds/my-role
# vault lease revoke aws/creds/my-role/0bce0782-32aa-25ec-f61d-c026ff22106
