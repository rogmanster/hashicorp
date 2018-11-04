#!/bin/bash

## VAULT AWS Authentication Use Case ##
# This script will set up Vault AWS EC2 Authentication on a HashiStack Dev Instance.
# It is serving as the Vault Server Instance and a EC2 "Client" Instance.
# The EC2 Instance will use it's signed Identity Cert to authenticate to Vault.
# Once the EC2 Instance gets a Vault token, it can retrieve a secret from Vault.

## Prerequisites ##
# Deploy HashiStack Dev Instance on EC2 from TFE
# ip=<external IP of EC2 Instance>
# export $ip
# export $VAULT_ADDR

## Set Vault Premium License
vault write sys/license text=$VAULT_PREMIUM_LICENSE

## Following to be performed by Vault Admin
echo "PERSONA - ADMIN"
echo

# Add secret to Vault to be retrieved after scucessful Authentication
echo "writing kv secret to Vault..."
echo
echo "vault kv put secret/mysecret milli=vanilli"
vault kv put secret/mysecret milli=vanilli
echo

read -p "press enter to continue..."
echo

# Vault Commands to enable AWS Authentication
echo "enabling Vault authentication..."
echo
echo "vault auth enable aws"
echo "vault write auth/aws/config/client secret_key=xxxxxxxxx access_key=yyyyyyyyyy"
echo "vault write auth/aws/role/dev-role auth_type=ec2 bound_region=us-west-2 policies=dev max_ttl=500h"
echo
vault auth enable aws
vault write auth/aws/config/client secret_key=$AWS_SECRET_ACCESS_KEY access_key=$AWS_ACCESS_KEY_ID
vault write auth/aws/role/dev-role auth_type=ec2 bound_region=us-west-2 policies=dev max_ttl=500h
echo
read -p "press enter to continue..."
echo

# Configure Vault policy for dev
echo "writing Vault policy for dev..."
echo
echo "path "secret/metadata/" { capabilities = ["list"] }"
echo "path "secret/data/mysecret" { capabilities = ["read"]}"
echo
echo '
path "secret/metadata/" {
  capabilities = ["list"]
}

path "secret/data/mysecret" {
  capabilities = ["read"]
}' | vault policy write dev -
echo
read -p "press enter to continue..."
echo

## Following to be performed by EC2 Client Instance ##
# Instance to get signed Indentity cert from EC2 and send to VAULT
# Vault will validate the Instance Identity with AWS
# Vault will return a json output with a token
echo "PERSONA - APP or EC2 Instance"
echo
echo "EC2 Instance fetching signed Identity Cert from AWS..."
echo
echo "ssh ec2-user@$ip -i ~/projects/vault/*.pem curl -s http://169.254.169.254/latest/dynamic/instance-identity/pkcs7 | tr -d '\n'"
echo
INSTANCE_IDENTITY_CERT=$(ssh ec2-user@$ip -i ~/projects/vault/*.pem curl -s http://169.254.169.254/latest/dynamic/instance-identity/pkcs7 | tr -d '\n')
echo "The retrieved cert is: " $INSTANCE_IDENTITY_CERT
echo
echo "EC2 Instance authenticating with Vault..."
echo
echo "curl -s -X POST ""$VAULT_ADDR"/v1/auth/aws/login" -d '{ "role":"dev-role", "pkcs7":"'$INSTANCE_IDENTITY_CERT'","nonce":"5defbf9e-a8f9-3063-bdfc-54b7a42a1f95"}' | jq -r .auth.client_token )"
echo
TOKEN=$(curl -s -X POST ""$VAULT_ADDR"/v1/auth/aws/login" -d '{ "role":"dev-role", "pkcs7":"'$INSTANCE_IDENTITY_CERT'","nonce":"5defbf9e-a8f9-3063-bdfc-54b7a42a1f95"}' | jq -r .auth.client_token )
echo "Vault token is: "$TOKEN
echo
read -p "press enter to continue..."
echo

# EC2 Instance to retrieve secret using token from Vault
echo "EC2 Instance using Vault token to retrieve secret from Vault..."
echo
echo "curl -s --header "X-Vault-Token: "$TOKEN"" "$VAULT_ADDR"/v1/secret/data/mysecret | jq -r '.data.data'"
echo
curl -s --header "X-Vault-Token: $TOKEN" "$VAULT_ADDR"/v1/secret/data/mysecret | jq -r '.data.data'
