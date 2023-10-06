#!/bin/bash

start_server(){
# bash/usr/bin/entrypoint
    sleep infinity
    exit;
}

catalog_file="/data/catalog.json"
subjects_file="/data/source_subjects.txt"
languages_file="/data/source_languages.txt"
types_file="/data/source_metadata_types.txt"

subjects=$(cat "$subjects_file" | tr '\n' ',' | sed -e 's/ /%20/g')
langs=$(cat "$languages_file" | tr '\n' ',')
types=$(cat "$types_file" | tr '\n' ',')

if test -f "$catalog_file"; then
    echo "Catalog already downloaded. Starting server..."
    # start_server
else
    wget -q --spider http://google.com

    if [ $? -ne 0 ]; then
        echo "Cannot get online to download from DCS Prod. Starting server..."
        start_server
    fi
fi

curl "https://git.door43.org/api/v1/catalog/search?lang=$langs&subjects=$subjects&metadataType=$types" --output "$catalog_file"

apk add jq

jq -r '.data[] | .owner + "/" + .name' "$catalog_file" | sort | while read full_name; do
    echo "Downloading $full_name"
    su git -c "/app/gitea/gitea dump-repo --git_service gitea --repo_dir '/tmp/$full_name' --clone_addr 'https://git.door43.org/$full_name'  --auth_token d9a7c5688b751a0f4e3fd26a721d9f67fd0ceed3"
    echo "Loading $full_name"
    owner_repo=$(echo "$full_name" | sed -e 's/\// --repo_name /')
    su git -c "/app/gitea/gitea restore-repo --repo_dir '/tmp/$full_name' --owner_name '$owner_repo'"
done

start_server