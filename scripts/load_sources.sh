#!/bin/bash

set -e

catalog_file="/data/catalog.json"
owners_file="/data/source_owners.txt"
subjects_file="/data/source_subjects.txt"
languages_file="/data/source_languages.txt"
types_file="/data/source_metadata_types.txt"

echo "WARNING!!! THIS WILL RESET __ALL__ SOURCE REPOS THAT MEET THE CRITERIA IN THE source_*.txt files!!!!!"

curl -sSf https://git.door43.org &> /dev/null

if [ $? -ne 0 ]; then
    echo "Cannot get online to download from DCS Prod."
    exit 1;
fi

owners=$(cat "$owners_file" | tr '\n' ',')
subjects=$(cat "$subjects_file" | tr '\n' ',')
langs=$(cat "$languages_file" | tr '\n' ',')
types=$(cat "$types_file" | tr '\n' ',')

curl --get \
     --data-urlencode "owner=$owners" \
     --data-urlencode "lang=$langs" \
     --data-urlencode "subject=$subjects" \
     --data-urlencode "metadataType=$types" \
     --output "$catalog_file" \
     https://git.door43.org/api/v1/catalog/search

apk add jq
apk add yq

jq -c '.data[]' "$catalog_file" | while read entry; do
    owner=$(echo $entry | jq -r '.owner')
    repo=$(echo $entry | jq -r '.name')
    full_name="$owner/$repo"
    if ! test -d "/tmp/$full_name"; then
        echo "Downloading $full_name"
        su git -c "/app/gitea/gitea dump-repo --git_service gitea --repo_dir '/tmp/$full_name' --clone_addr 'https://git.door43.org/$full_name' --units releases --auth_token d54df420a8d39f9cec8394a73c6b44a2afcd0916"
    fi
    release_file="/tmp/$full_name/release.yml"
    if test -f "$release_file"; then
        echo Deleting assets in releases.yml file
        yq e 'del(.[].assets)' "$release_file" > "$release_file.tmp"
        mv "$release_file.tmp" "$release_file"
    fi
    echo "Creating org if doesn't exist"
    curl -X 'POST' \
        'http://localhost:3000/api/v1/orgs?token=f1200db0ecd5a597f84f624b467df7a1843e5211' \
        -H 'accept: application/json' \
        -H 'Content-Type: application/json' \
        -d "{
            \"repo_admin_change_team_access\": true,
            \"username\": \"$owner\",
            \"visibility\": \"public\"
        }" >& /dev/null
    echo "Deleting repo if it exists"
    curl -X 'DELETE' \
        "http://localhost:3000/api/v1/repos/$full_name?token=f1200db0ecd5a597f84f624b467df7a1843e5211" >& /dev/null
    echo "Loading $full_name"
    echo su git -c "/app/gitea/gitea restore-repo --repo_dir '/tmp/$full_name' --owner_name '$owner'  --repo_name '$repo' --units releases"
    su git -c "/app/gitea/gitea restore-repo --repo_dir '/tmp/$full_name' --owner_name '$owner'  --repo_name '$repo' --units releases"
    su git -c "/app/gitea/gitea door43metadata --owner '$owner' --repo '$repo'"
    rm -rf "/tmp/$full_name"
done
