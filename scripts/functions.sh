#!/bin/bash

set -e

SCRIPTS_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)
source "$SCRIPTS_DIR/vars.sh"

exitIfNotOnline() {
    curl -sSf "${API_URL}/version" &> /dev/null

    if [ $? -ne 0 ]; then
        echo "Cannot get online to download from $REMOTE_DCS_URL"
        exit 1;
    fi
}

ensureRootUser() {
    # Creates a local admin user if it doesn't exist, and makes sure the password is set to $LOCAL_ADMIN_PASSWORD
    if ! userExists "$LOCAL_ADMIN_USER"; then
        "$GITEA" admin user create --username "$LOCAL_ADMIN_USER" --password "$LOCAL_ADMIN_PASSWORD" --email "$LOCAL_ADMIN_USER@no-reply.localhost"  --admin || true
    fi
    "$GITEA" admin user change-password --username "$LOCAL_ADMIN_USER" --password "$LOCAL_ADMIN_PASSWORD"
}

loadSources() {
    exitIfNotOnline

    echo "WARNING!!! THIS WILL RESET __ALL__ SOURCE REPOS THAT MEET THE CRITERIA IN THE source_*.txt files!!!!!"
    echo -n "Do you wish to continue? (y/N): "
    read confirm
    if [ -z "$confirm" ] || ([ "$confirm" != "y" ] && [ "$confim" != "Y" ]); then
        echo "Exiting."
        exit 1
    fi

    owners=$(tr '\n' ',' < "$OWNERS_FILE"| sed -r 's/#[^,]+,*//g' | sed 's/,$//')
    subjects=$(tr '\n' ',' < "$SUBJECTS_FILE"| sed -r 's/#[^,]+,*//g' | sed 's/,$//')
    langs=$(tr '\n' ',' < "$LANGUAGES_FILE"| sed -r 's/#[^,]+,*//g' | sed 's/,$//')
    types=$(tr '\n' ',' < "$TYPES_FILE"| sed -r 's/#[^,]+,*//g' | sed 's/,$//')

    echo "OWNERS: $owners"
    echo "LANGS: $langs"
    echo "SUBJECTS: [see source_subjects.txt]"
    echo "METADATA TYPES: $types"

    curl --get \
         --data-urlencode "owner=$owners" \
        --data-urlencode "lang=$langs" \
        --data-urlencode "subject=$subjects" \
        --data-urlencode "metadataType=$types" \
        --output "$SOURCE_CATALOG_FILE" \
        "${API_URL}/catalog/search" >& /dev/null

    jq -c '.data[]' "$SOURCE_CATALOG_FILE" | while read -r entry; do
        owner=$(echo "$entry" | jq -r '.owner')
        repo=$(echo "$entry" | jq -r '.name')
        importRepoFromRemote "$owner" "$repo"
    done

    echo "Finished downloading and loading all source repos that match the criteria."
}

loadTargets() {
    exitIfNotOnline

    echo "WARNING!!! THIS WILL RESET __ALL__ TARGET REPOS OF THE GIVEN ORG!!!!!"
    echo -n "Enter the target org that exists on the remote DCS: "
    read org
    if [ -z "$org" ] || [ "$org" == "" ]; then
        echo "Nothing loaded. Exiting."
        exit 1
    fi

    echo -n "Enter the target language (Blank for all): "
    read lang

    lang_urlencode_str=""
    if [ "$lang" != "" ]; then
        lang_urlencode_str="lang=$lang"
    fi

    curl --get \
         --data-urlencode "owner=$org" \
        --data-urlencode "$lang_urlencode_str" \
        --data-urlencode "stage=latest" \
        --output "$TARGET_CATALOG_FILE" \
        "${API_URL}/catalog/search" >& /dev/null

    jq -c '.data[]' "$TARGET_CATALOG_FILE" | while read -r entry; do
        owner=$(echo "$entry" | jq -r '.owner')
        repo=$(echo "$entry" | jq -r '.name')
        release=$(echo "$entry" | jq -r '.release')
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
        curl -f "$API_URL/repos/$ful_name/releases" && \
            "${GITEA}" dump-repo --git_service gitea --repo_dir "$TMPDIR/$full_name" --clone_addr "$REMOTE_DCS_URL/$full_name" --units releases || \
            "${GITEA}" dump-repo --git_service gitea --repo_dir "$TMPDIR/$full_name" --clone_addr "$REMOTE_DCS_URL/$full_name"
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

updateAllTargetRepos() {
    echo -n "Enter the org to update: "
    read org
    if [ "$org" == "" ]; then
        echo "No org given. Exiting."
        exit 1
    fi

    exitIfNotOnline

    org_dir="$SCRIPTS_DIR/../git/repositories/$org"
    for d in "$org_dir"/*; do
        echo "$d"
        cd "$d" || exit
        repo=${d##*/}
        git config --global --add safe.directory "$d"
        git pull "$REMOTE_HOST_URL/$repo" master:master
        echo "Updated the master branch of $org/${repo%.*} from $REMOTE_DCS_URL/$repo"
    done

    echo "Finished updating all repos for target org $org."
}

uploadAllTargetRepos() {
    exitIfNotOnline

    # echo -n "Enter your remote username: "
    # read user
    # if [ "$user" == "" ]; then
    #     echo "No username given. Exiting."
    #     exit 1
    # fi

    # echo -n "Enter your remote password: "
    # read pass
    # if [ "$pass" == "" ]; then
    #     echo "No password given. Exiting."
    #     exit 1
    # fi

    echo -n "Enter the org to upload: "
    read org
    if [ "$org" == "" ]; then
        echo "No org given. Exiting."
        exit 1
    fi

    # dcs_url=${REMOTE_DCS_URL/\/\////$user:$pass@}

    org_dir="$SCRIPTS_DIR/../git/repositories/$org"
    for d in "$org_dir"/*; do
        echo "$d"
        cd "$d" || exit
        repo=${d##*/}
        git config --global --add safe.directory "$d"
        git push "$REMOTE_DCS_URL/$repo" master:master
        echo "Pushed the master branch of $org/${repo%.*} to $REMOTE_DCS_URL/$repo"
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
