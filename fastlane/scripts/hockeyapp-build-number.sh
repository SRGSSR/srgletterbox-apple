#!/bin/bash -e -x

BUILD_NUMBER=0

for APP_ID; do
  # HockeyApp token from Pierre-Yves Bertholon account
  # Get only app versions which are downloadable (status = 2) or not (status = 1). Don't get removed versions (status = -1)
    APP_BUILD_NUMBER=$(curl --silent --header "X-HockeyAppToken: 54ee058e9e6248b1b3f7b61cc8d598ff" "https://rink.hockeyapp.net/api/2/apps/${APP_ID}/app_versions?format=xml" | xpath "/response/app-versions/app-version[status = 2 or status = 1][1]/version/text()" 2> /dev/null)
    if [ ${APP_BUILD_NUMBER} -gt ${BUILD_NUMBER} ]; then
        BUILD_NUMBER=${APP_BUILD_NUMBER}
    fi
done

export HOCKEY_APP_BUILD_NUMBER=${BUILD_NUMBER}
echo ${BUILD_NUMBER}

