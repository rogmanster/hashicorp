###################
## Prerequisites ##
###################

## Run the script remotely on HashiStack AWS Dev instance.
# export ip=<external IP of EC2 Instance>
# export $VAULT_ADDR
# ssh ec2-user@$ip -i ~/projects/workspaces/terraform-aws-hashistack-dev/*.pem 'bash -s' < ~/projects/vault/postgres_cli.sh
# ssh ec2-user@$ip -i ~/projects/vault/*.pem 'bash -s' < ~/projects/vault/postgres_cli.sh

## Run the script remotely on Vagrant Dev instance.
# export VAULT_ADDR=http://127.0.0.1:8200
# vagrant ssh -c 'bash -s' < /Users/rogman/projects/vault/postgres_cli.sh

########################
## POSTGRES CONTAINER ##
########################

## Deploy postgres docker container
echo "running postgres container..."
echo
sudo docker run -d --name postgres -p 5432:5432 postgres
sleep 3

echo
echo "running psql commands to configure db and add users..."
echo
# Configure databases and dbadmin account
sudo docker exec postgres psql -U postgres -c "CREATE DATABASE myapp;"
sudo docker exec postgres psql -U postgres -c "CREATE USER roger WITH PASSWORD 'password123';"
sudo docker exec postgres psql -U postgres -c "ALTER USER roger WITH SUPERUSER;"
sudo docker exec postgres psql -U postgres -c "CREATE DATABASE supercoolapp;"
sudo docker exec postgres psql -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE supercoolapp to roger;"
echo
echo "Postgres DB creation - COMPLETE!"
echo

#########################################
## VAULT POSTGRES ENGINE CONFIGURATION ##
#########################################

## Set Vault Premium License
vault write sys/license text=$VAULT_PREMIUM_LICENSE

## Vault Configurations
echo "PERSONA - ADMIN"
echo "Configure vault postgres database plugin..."
echo

## Vault configuration of Postgresql secret backend
vault secrets enable database
vault write database/config/postgres \
plugin_name=postgresql-database-plugin \
allowed_roles=readonly \
  connection_url="user=roger password=password123 \
  host=localhost port=5432 dbname=supercoolapp sslmode=disable"

echo
vault read database/config/postgres

## Vault Postgres role creation
echo
echo "Configure role for postgres database access..."
echo
vault write database/roles/readonly db_name=postgres \
creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; GRANT SELECT ON ALL TABLES IN SCHEMA public TO \"{{name}}\";" \
default_ttl=1h max_ttl=24h

echo
vault read database/roles/readonly

echo
echo "Vault postgres database secret engine configuration - COMPLETE!"
echo
read -p "press enter to continue..."
echo
clear

####################################
## VAULT READ POSTGRES CREDENTIAL ##
####################################

## Read dynamically generated credentials
echo "PERSONA - APP"
echo "request a dynamic secret from Vault..."
echo
vault read database/creds/readonly
echo

## Print IP Address to be used for PSQL ADMIN Connection
echo "Host IP Address for PSQL ADMIN Connection: "
hostname -I | awk '{print $1}'
echo
