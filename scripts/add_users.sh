#!/bin/bash

set -e

prefix=$1
num=$2
password=$3
org=$4
start_at=$5

[ -z $prefx ] && prefix="user"
[ -z $num ] && num="10"
[ -z $password ] && password="password"
[ -z $start_at ] && start_at="1"

end_at=$(( ${start_at} + ${num} - 1))

echo "Creating $num users with the prefix \"$prefix\" and the password \"$password\", starting at #$start_at."

if [ -z $org ]; then
    echo "NOTE: Not adding them to any org."
else
    echo "NOTE: Adding users to the Owners team of the $org org."
    echo "Creating org $org in case it doesn't exist (ignore message if it does):"
    curl -X 'POST' \
        "http://localhost:3000/api/v1/orgs?token=$ROOT_TOKEN" \
        -H 'accept: application/json' \
        -H 'Content-Type: application/json' \
        -d "{
            \"repo_admin_change_team_access\": true,
            \"username\": \"$org\",
            \"visibility\": \"public\"
        }"
    team_id=$(curl -X 'GET' "http://localhost:3000/api/v1/orgs/$org/teams/search?q=Owners&token=$ROOT_TOKEN" | jq '.data[].id')
    echo "TEAM ID: $team_id"
fi

for i in $(seq $start_at $end_at); do
    username="$prefix$i"
    echo "Creating user #$i: $username"
    $GITEA admin user create --username "$username" --email "$username@noreply.localhost" --password "$password" --must-change-password false
    if [ ! -z $org ]; then
        curl -X 'PUT' "http://localhost:3000/api/v1/teams/$team_id/members/$username?token=$ROOT_PASSWORD"        
    fi
done
