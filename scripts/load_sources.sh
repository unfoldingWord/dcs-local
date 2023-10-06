#!/bin/bash

# bash /usr/bin/entrypoint &

done_file="/data/DONE"
catalog_file="/data/catalog.json"

if test -f "$done_file"; then
    echo "Source repos already downloaded and imported. Removed the DONE file if you want to run again."
    exit 1;
fi

wget -q --spider https://git.door43.org

if [ $? -ne 0 ]; then
    echo "Cannot get online to download from DCS Prod."
    exit 1;
fi

owners_file="/data/source_owners.txt"
subjects_file="/data/source_subjects.txt"
languages_file="/data/source_languages.txt"
types_file="/data/source_metadata_types.txt"

owners=$(cat "$owners_file" | tr '\n' ',')
subjects=$(cat "$subjects_file" | tr '\n' ',' | sed -e 's/ /%20/g')
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

jq -r '.data[] | .owner + "/" + .name' "$catalog_file" | sort | while read full_name; do
    echo "Downloading $full_name"
    su git -c "/app/gitea/gitea dump-repo --git_service gitea --repo_dir '/tmp/$full_name' --clone_addr 'https://git.door43.org/$full_name' --units releases --auth_token d54df420a8d39f9cec8394a73c6b44a2afcd0916"
    echo "Creating org if doesn't exist"
    curl -X 'POST' \
        'http://localhost:3000/api/v1/orgs?token=2c2e5fc8fcc8d9e7b0d2a62563312eae3659e264' \
        -H 'accept: application/json' \
        -H 'Content-Type: application/json' \
        -d '{
            "repo_admin_change_team_access": true,
            "username": "Door43-Catalog",
            "visibility": "public",
        }'
    echo "Loading $full_name"
    owner_repo=$(echo "$full_name" | sed -e 's/\// --repo_name /')
    su git -c "/app/gitea/gitea restore-repo --repo_dir '/tmp/$full_name' --owner_name '$owner_repo'"
done

touch "$done_file"
