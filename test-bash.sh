#!/bin/bash
urlencode() {
    # urlencode <string>
    old_lc_collate=$LC_COLLATE
    LC_COLLATE=C
    
    local length="${#1}"
    for (( i = 0; i < length; i++ )); do
        local c="${1:i:1}"
        case $c in
            [a-zA-Z0-9.~_-]) printf "$c" ;;
            *) printf '%%%02X' "'$c" ;;
        esac
    done
    
    LC_COLLATE=$old_lc_collate
}

tmp=(*.jsonld)
REPORT_LOCATION=$(echo "${tmp[0]}")

if [ ! -f "$REPORT_LOCATION" ]; then
    echo "Report location not provided, or file not found for upload."
    
    if [ ! -f "$1" ]; then
    	echo "(Report location provided: $1)"
    fi
    
    # Special casing here is in response to non-trivial performance implementations scanning an entire build workspace for candidate files
    
    #BDS default location is in the blackduck folder
    if [ -d "./blackduck" ]; then
        echo "Suggestions:"
        find ./blackduck -name '*_bdio.jsonld' -print
    fi
    
    #Gradle default location is in the build folder
    if [ -d "./build" ]; then
    	echo "Suggestions:"
    	find ./build -name '*_bdio.jsonld' -print
    fi
    
    #Maven default is in a target folder
    if [ -d "./target" ]; then
    	echo "Suggestions:"
    	find ./target -name '*_bdio.jsonld' -print
    fi
    
    exit 1
fi

#Log that the script download is complete and proceeding
echo "Uploading report at $1"

#Log the curl version used
curl --version

#CIRCLE_ and CI_ environment variables used here are documented at https://circleci.com/docs/1.0/environment-variables/
if [ -z "$APPVEYOR_PULL_REQUEST_NUMBER" ]; then
	COPILOT_PULL_REQUEST=false
else
    COPILOT_PULL_REQUEST=$(urlencode $APPVEYOR_PULL_REQUEST_NUMBER)
fi

COPILOT_REPO_SLUG=$(urlencode $APPVEYOR_REPO_NAME)
COPILOT_BRANCH=$(urlencode $APPVEYOR_REPO_BRANCH)

COPILOT_URL="https://copilot-valid.blackducksoftware.com/hub/import?provider=github&repository=$COPILOT_REPO_SLUG&branch=$COPILOT_BRANCH&pull_request=$COPILOT_PULL_REQUEST"

curl -g -v -f -X POST -d @$1 -H 'Content-Type:application/ld+json' "$COPILOT_URL"

#Exit with the curl command's output status
exit $?
