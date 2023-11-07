#!/bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
DCS_HOST="${DCS_HOST:-https://git.door43.org}"
API_URL="${DCS_HOST}/api/v1"

GITEA="${GITEA:-tea/gitea}"
TMPDIR="${TMPDIR:-/tmp}"

OWNERS_FILE="${OWNERS_FILE:-$SCRIPT_DIR/../source_owners.txt}"
SUBJECTS_FILE="${SUBJECTS_FILE:-$SCRIPT_DIR/../source_subjects.txt}"
LANGUAGES_FILE="${LANGUGES_FILE:-$SCRIPT_DIR/../source_languages.txt}"
TYPES_FILE="${TYPES_FILE:-$SCRIPT_DIR/../source_metadata_types.txt}"

ROOT_USER="root"
ROOT_EMAIL="root@localhost.com"
ROOT_PASSWORD="asecurepassword"

source "$SCRIPT_DIR/root_token.sh"

exitIfNotOnline() {
    echo "${API_URL}/version"
    curl -sSf "${API_URL}/version" &> /dev/null

    if [ $? -ne 0 ]; then
        echo "Cannot get online to download from $DCS_HOST"
        exit 1;
    fi
}

importRepoFromRemote() {
    owner=$1
    repo=$2
    full_name="$owner/$repo"
    if ! test -d "$TMPDIR/$full_name"; then
        echo "Downloading $full_name"
        "${GITEA}" dump-repo --git_service gitea --repo_dir "$TMPDIR/$full_name" --clone_addr "https://git.door43.org/$full_name" --units releases --auth_token d54df420a8d39f9cec8394a73c6b44a2afcd0916
    fi
    release_file="$TMPDIR/$full_name/release.yml"
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
        }"
    echo "Deleting repo if it exists"
    curl -X 'DELETE' \
        "http://localhost:3000/api/v1/repos/$full_name?token=f1200db0ecd5a597f84f624b467df7a1843e5211"
    echo "Loading $full_name"
    "$GITEA" restore-repo --repo_dir "$TMPDIR/$full_name" --owner_name "$owner" --repo_name "$repo" --units releases
    "$GITEA" door43metadata --owner "$owner" --repo "$repo"
    rm -rf "$TMPDIR/$full_name"
}