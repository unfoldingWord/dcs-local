#!/bin/bash

source ./common.sh

loadTarget() {
    echo "WARNING!!! THIS WILL RESET __ALL__ TARGET REPOS OF THE GIVEN ORG!!!!!"

    org=$1

    if [ -z $org ]; then
        echo "No org proviced. Please provide an org that is NOT in the source_owners.txt file"
    fi

    while read -r line; do
        if [ "$line" == "$org" ]; then
            echo "Sorry, you can't import an org that is in the source_owners.txt file."
            exit 1
        fi
    done < "$OWNERS_FILE"

    exitIfNotOnline

    curl --get \
         --output "$TMPDIR/target_catalog.json" \
        "https://git.door43.org/api/v1/catalog/search?owner=$org&stage=latest&metadataType=rc" >& /dev/null

    apk add jq
    apk add yq

    jq -c '.data[]' "$TMPDIR/target_catalog.json" | while read entry; do
        repo=$(echo $entry | jq -r '.name')
        full_name="$org/$repo"
        if ! test -d "$TMPDIR/$full_name"; then
            echo "Downloading $full_name"
            "$GITEA" dump-repo --git_service gitea --repo_dir "$TMPDIR/$full_name" --clone_addr "https://git.door43.org/$full_name" --units releases --auth_token d54df420a8d39f9cec8394a73c6b44a2afcd0916
        fi
        release_file="$TMPDIR/$full_name/release.yml"
        if test -f "$release_file"; then
            echo Deleting assets in releases.yml file
            yq e 'del(.[].assets)' "$release_file" > "$release_file.tmp"
            mv "$release_file.tmp" "$release_file"
        fi
        echo "Creating org if doesn't exist"
        curl -X 'POST' \
            "http://localhost:3000/api/v1/orgs?token=$ROOT_TOKEN" \
            -H 'accept: application/json' \
            -H 'Content-Type: application/json' \
            -d "{
                \"repo_admin_change_team_access\": true,
                \"username\": \"$org\",
                \"visibility\": \"public\"
            }"
        echo "Deleting repo if it exists"
        curl -X 'DELETE' "http://localhost:3000/api/v1/repos/$full_name?token=f1200db0ecd5a597f84f624b467df7a1843e5211"
        echo "Loading $full_name"
        echo "$GITEA" restore-repo --repo_dir "$TMPDIR/$full_name" --owner_name "$org"  --repo_name "$repo" --units releases
        "$GITEA" restore-repo --repo_dir "$TMPDIR/$full_name" --owner_name "$org"  --repo_name "$repo" --units releases
        "$GITEA" door43metadata --owner "$org" --repo "$repo"
        rm -rf "$TMPDIR/$full_name"
    done

    echo "Finished downloading and loading all repos for target org $org."
}