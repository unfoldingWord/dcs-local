#!/bin/bash

source ./common.sh

uploadAllTargetRepos() {
    dcs_url=$1
    message="Please provide a DCS URL in the form of \"https://<username>:<password>@git.door43.org/<org>\" where <org> is also on this local copy of DCS. You cannot upload source org repos."

    org=${dcs_url##*/}
    
    if [ -z $org ]; then
        echo "No org found in the URL."
        echo $message
        exit 1
    fi
    
    while read -r line; do
        if [ "$line" == "$org" ]; then
            echo "Sorry, you can't upload the repos of an org that is in the $OWNERS_FILE file."
            exit 1
        fi
    done < "$OWNERS_FILE"
    
    exitIfNotOnline
    
    org_dir="../git/repositories/$org"
    for d in $org_dir/*; do
        echo $d
        cd "$d"
        repo=${d##*/}
        git config --global --add safe.directory "$d"
        git push "$dcs_url/$repo" master:master
        echo "Pushed the master branch of $org/${repo%.*} to $dcs_url/$repo"
    done
    
    echo "Finished uploading all repos for target org $org."
}
