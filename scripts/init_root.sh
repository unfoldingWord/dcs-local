#!/bin/bash

source ./common.sh

"$GITEA" admin user create --username $ROOT_USER --password $ROOT_PASSWORD --email $ROOT_EMAIL --must-change-password false

token_name="dcs-local-$(tr -dc A-Za-z0-9 </dev/urandom | head -c 13 ; echo '')"
token=$("$GITEA" admin user generate-access-token --username root --token-name "$token_name" dcs-local --scopes all | cut -d' ' -f6)

echo -e "ROOT_TOKEN=$token\nROOT_TOKEN_NAME=$token_name" > "$SCRIPT_DIR/root_token.sh"

source "$SCRIPT_DIR/root_token.sh"
