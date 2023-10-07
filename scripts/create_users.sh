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
    team_id=$(curl -X 'GET' "http://localhost:3000/api/v1/orgs/$org/teams/search?q=Owners&token=f1200db0ecd5a597f84f624b467df7a1843e5211" | jq '.data[].id')
    echo "TEAM ID: $team_id"
fi

for i in $(seq $start_at $end_at); do
    username="$prefix$i"
    echo "Creating user #$i: $username"
    curl -X 'POST' \
        'http://localhost:3000/api/v1/admin/users?token=f1200db0ecd5a597f84f624b467df7a1843e5211' \
        -H 'accept: application/json' \
        -H 'Content-Type: application/json' \
        -d "{
            \"username\": \"$username\",
            \"email\": \"$username@noreply.localhost\",
            \"password\": \"$password\",
            \"send_notify\": false,
            \"must_change_password\": false
        }"
    if [ ! -z $org ]; then
        curl -X 'PUT' \
            "http://localhost:3000/api/v1/teams/$team_id/members/$username?token=f1200db0ecd5a597f84f624b467df7a1843e5211"        
    fi
done
