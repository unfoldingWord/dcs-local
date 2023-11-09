#!/bin/bash

set -e

SCRIPTS_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)
source "$SCRIPTS_DIR/vars.sh"

exitIfNotOnline() {
    curl -sSf "${API_URL}/version" &> /dev/null

    if [ $? -ne 0 ]; then
        echo "Cannot get online to download from $DCS_HOST"
        exit 1;
    fi
}

ensureRootUser() {
    # Creates a root user if it doesn't exist, and makes sure the password is set to $ROOT_PASSWORD
    if ! userExists "root"; then
        echo "$GITEA" admin user create --username "$ROOT_USER" --password "$ROOT_PASSWORD" --email "$ROOT_USER@no-reply.localhost" --admin
        "$GITEA" admin user create --username "$ROOT_USER" --password "$ROOT_PASSWORD" --email "$ROOT_USER@no-reply.localhost"  --admin || true
    fi
    "$GITEA" admin user change-password --username "$ROOT_USER" --password "$ROOT_PASSWORD"
}

loadSources() {
    exitIfNotOnline

    echo "WARNING!!! THIS WILL RESET __ALL__ SOURCE REPOS THAT MEET THE CRITERIA IN THE source_*.txt files!!!!!"

    owners=$(tr '\n' ',' < "$OWNERS_FILE"| sed -r 's/#[^,]+,*//g' | sed 's/,$//')
    subjects=$(tr '\n' ',' < "$SUBJECTS_FILE"| sed -r 's/#[^,]+,*//g' | sed 's/,$//')
    langs=$(tr '\n' ',' < "$LANGUAGES_FILE"| sed -r 's/#[^,]+,*//g' | sed 's/,$//')
    types=$(tr '\n' ',' < "$TYPES_FILE"| sed -r 's/#[^,]+,*//g' | sed 's/,$//')

    curl --get \
         --data-urlencode "owner=$owners" \
        --data-urlencode "lang=$langs" \
        --data-urlencode "subject=$subjects" \
        --data-urlencode "metadataType=$types" \
        --output "$TMPDIR/source_catalog.json" \
        https://git.door43.org/api/v1/catalog/search >& /dev/null

    jq -c '.data[]' "$TMPDIR/source_catalog.json" | while read -r entry; do
        owner=$(echo "$entry" | jq -r '.owner')
        repo=$(echo "$entry" | jq -r '.name')
        echo "OWNER $owner REPO $repo"
        importRepoFromRemote "$owner" "$repo"
    done

    echo "Finished downloading and loading all source repos that match the criteria."
}

loadTargets() {
    echo "WARNING!!! THIS WILL RESET __ALL__ TARGET REPOS OF THE GIVEN ORG!!!!!"

    org=$1

    if [ -z "$org" ]; then
        echo "No org proviced. Please provide an org that is NOT in the source_owners.txt file"
    fi

    while read -r line; do
        if [ "$line" == "$org" ]; then
            echo "Sorry, you can't import an org that is in the source_owners.txt file."
            exit 1
        fi
    done < "$OWNERS_FILE"

    exitIfNotOnline

    echo curl --get \
         --output "$TMPDIR/target_catalog.json" \
        "https://git.door43.org/api/v1/catalog/search?owner=$org&stage=latest&metadataType=rc" >& /dev/null

    jq -c '.data[]' "$TMPDIR/target_catalog.json" | while read -r entry; do
        owner=$(echo "$entry" | jq -r '.owner')
        repo=$(echo "$entry" | jq -r '.name')
        importRepoFromRemote "$owner" "$repo"
    done

    echo "Finished downloading and loading all repos for target org $org."
}

importRepoFromRemote() {
    owner=$1
    repo=$2
    full_name="$owner/$repo"
    ensureRootUser
    if ! test -d "$TMPDIR/$full_name"; then
        echo "Downloading $full_name..."
        echo "${GITEA}" dump-repo --git_service gitea --repo_dir "$TMPDIR/$full_name" --clone_addr "https://git.door43.org/$full_name" --units releases --auth_token d54df420a8d39f9cec8394a73c6b44a2afcd0916
        "${GITEA}" dump-repo --git_service gitea --repo_dir "$TMPDIR/$full_name" --clone_addr "https://git.door43.org/$full_name" --units releases --auth_token d54df420a8d39f9cec8394a73c6b44a2afcd0916
    fi
    release_file="$TMPDIR/$full_name/release.yml"
    if test -f "$release_file"; then
        echo Deleting assets in releases.yml file
        yq e 'del(.[].assets)' "$release_file" > "$release_file.tmp"
        mv "$release_file.tmp" "$release_file"
    fi
    echo "Creating org if doesn't exist..."
    curl -X 'POST' \
        "$LOCALHOST/api/v1/orgs" \
        -H 'accept: application/json' \
        -H 'Content-Type: application/json' \
        -d "{ \
            \"repo_admin_change_team_access\": true, \
            \"username\": \"$owner\", \
            \"visibility\": \"public\" \
        }"
    echo "Deleting repo if it exists..."
    curl -X 'DELETE' \
        "$LOCALHOST/api/v1/repos/$full_name"
    echo "Loading $full_name..."
    "$GITEA" restore-repo --repo_dir "$TMPDIR/$full_name" --owner_name "$owner" --repo_name "$repo" --units releases
    "$GITEA" door43metadata --owner "$owner" --repo "$repo"
    rm -rf "$TMPDIR/$full_name"
}

uploadAllTargetRepos() {
    dcs_url=$1
    message="Please provide a DCS URL in the form of \"https://<username>:<password>@git.door43.org/<org>\" where <org> is also on this local copy of DCS. You cannot upload source org repos."

    org=${dcs_url##*/}

    if [ -z "$org" ]; then
        echo "No org found in the URL."
        echo "$message"
        exit 1
    fi

    while read -r line; do
        if [ "$line" == "$org" ]; then
            echo "Sorry, you can't upload the repos of an org that is in the $OWNERS_FILE file."
            exit 1
        fi
    done < "$OWNERS_FILE"

    exitIfNotOnline

    org_dir="$SCRIPTS_DIR/../git/repositories/$org"
    for d in "$org_dir"/*; do
        echo "$d"
        cd "$d" || exit
        repo=${d##*/}
        git config --global --add safe.directory "$d"
        git push "$dcs_url/$repo" master:master
        echo "Pushed the master branch of $org/${repo%.*} to $dcs_url/$repo"
    done

    echo "Finished uploading all repos for target org $org."
}

userExists() {
    user="\<${1}\>" #for the regex
    users=( $(gitea admin user list| tail -n +2 | sed -r 's/^[^ ]+ +([^ ]+).*/\1/g'))

    if [[ ${users[@]} =~ $user ]]
    then
        return 0
    else
        return 1
    fi
}

addUsers() {
    prefix=$1
    num=$2
    password=$3
    org=$4
    start_at=$5

    [ -z "$prefx" ] && prefix="user"
    [ -z "$num" ] && num="10"
    [ -z "$password" ] && password="password"
    [ -z "$start_at" ] && start_at="1"

    end_at=$(( start_at + num - 1))

    echo "Creating $num users with the prefix \"$prefix\" and the password \"$password\", starting at #$start_at."

    ensureRootUser

    if [ -z "$org" ]; then
        echo "NOTE: Not adding them to any org."
    else
        echo "NOTE: Adding users to the Owners team of the $org org."
        echo "Creating org $org in case it doesn't exist (ignore message if it does):"
        curl -X 'POST' \
            "$LOCALHOST/api/v1/orgs" \
            -H 'accept: application/json' \
            -H 'Content-Type: application/json' \
            -d "{
                \"repo_admin_change_team_access\": true,
                \"username\": \"$org\",
                \"visibility\": \"public\"
            }"
        team_id=$(curl -X 'GET' "$LOCALHOST/api/v1/orgs/$org/teams/search?q=Owners" | jq '.data[].id')
        echo "TEAM ID: $team_id"
    fi

    for i in $(seq "$start_at" "$end_at"); do
        username="$prefix$i"
        if userExists $username; then
            echo "User $username already exists"
        else
            echo "Creating user #$i: $username"
            $GITEA admin user create --username "$username" --email "$username@noreply.localhost" --password "$password" --must-change-password false
        fi
        if [ -n "$org" ]; then
            curl -X 'PUT' "$LOCALHOST/api/v1/teams/$team_id/members/$username"
            echo "Added $username to the $org org"
        fi
    done
}
