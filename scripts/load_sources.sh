#!/bin/bash

source ./common.sh

loadSources() {
    exitIfNotOnline

    echo "WARNING!!! THIS WILL RESET __ALL__ SOURCE REPOS THAT MEET THE CRITERIA IN THE source_*.txt files!!!!!"

    owners=$(cat "$$OWNERS_FILE" | tr '\n' ',')
    subjects=$(cat "$SUBJECTS_FILE" | tr '\n' ',')
    langs=$(cat "$LANGUAGES_FILES" | tr '\n' ',')
    types=$(cat "$TYPES_FILE" | tr '\n' ',')

    curl --get \
         --data-urlencode "owner=$owners" \
        --data-urlencode "lang=$langs" \
        --data-urlencode "subject=$subjects" \
        --data-urlencode "metadataType=$types" \
        --output "$TMPDIR/source_catalog.json" \
        https://git.door43.org/api/v1/catalog/search >& /dev/null

    jq -c '.data[]' "$TMPDIR/source_catalog.json" | while read entry; do
        owner=$(echo $entry | jq -r '.owner')
        repo=$(echo $entry | jq -r '.name')
        importRepoFromRemote "$owner" "$repo"
    done

    echo "Finished downloading and loading all source repos that match the criteria."
}
