#!/usr/bin/env bash
set -x

if [ "${CONFIGURATION}" == "Debug" ] || [ "${ENABLE_PREVIEWS}" == "YES" ]; then
    exit 0
fi

export PATH="${PATH}:/usr/local/bin:/opt/local/bin:/opt/homebrew/bin"

SOURCE_RESOURCES_PATH="${SRCROOT}/Resources"
SOURCE_IOS_APPICON_PATH="${SOURCE_RESOURCES_PATH}/Images.xcassets/AppIcon.appiconset"
DUPLICATE_IOS_APPICON_PATH="${SOURCE_RESOURCES_PATH}/OriginalAppIcon.appiconset"
SOURCE_TVOS_APPICON_PATH="${SOURCE_RESOURCES_PATH}/Images.xcassets/App Icon & Top Shelf Image.brandassets/App Icon.imagestack/Back.imagestacklayer/Content.imageset"
DUPLICATE_TVOS_APPICON_PATH="${SOURCE_RESOURCES_PATH}/OriginalAppIcon.imagestack"

echo "Duplicate original icons..."

cp -fR "${SOURCE_IOS_APPICON_PATH}" "${DUPLICATE_IOS_APPICON_PATH}"
cp -fR "${SOURCE_TVOS_APPICON_PATH}" "${DUPLICATE_TVOS_APPICON_PATH}"

BUNDLE_IDENTIFIER=${PRODUCT_BUNDLE_IDENTIFIER}
BUILD_NUMBER=${CURRENT_PROJECT_VERSION}
VERSION_STRING=${MARKETING_VERSION}

echo "Version found ${CONFIGURATION}-${VERSION_STRING}-${BUILD_NUMBER}"

echo "Making ${CONFIGURATION} app icons..."

LAST_RUN_FILE="${SRCROOT}/Scripts/generate-icons-caches/generate-icons-last-run.txt"
CURRENT_RUN="${BUNDLE_IDENTIFIER}-${CONFIGURATION}-${BUILD_NUMBER}"
LAST_RUN=""

if [ -f "${LAST_RUN_FILE}" ]; then
    LAST_RUN=$(cat "${LAST_RUN_FILE}")
fi

if [ "${LAST_RUN}" == "${CURRENT_RUN}" ]; then
    echo "Last run had same configuration: ${CURRENT_RUN}. No need to recreate icons, except if not created before."
fi

set CONTENTS[0] = "${SOURCE_IOS_APPICON_PATH}/Contents.json"
set CONTENTS[1] = "${SOURCE_TVOS_APPICON_PATH}/Contents.json"

echo "Processing icons..."
for CONTENTS_JSON in "${SOURCE_IOS_APPICON_PATH}/Contents.json" "${SOURCE_TVOS_APPICON_PATH}/Contents.json";
do
    ICON_COUNT=$(jq -r '.images | length-1' "${CONTENTS_JSON}")
    for i in $(jot - 0 "${ICON_COUNT}");
    do
        filename=$(jq -r ".images[${i}] | .filename" "${CONTENTS_JSON}")
        scale=@$(jq -r ".images[${i}] | .scale" "${CONTENTS_JSON}")
        idiom=$(jq -r ".images[${i}] | .idiom" "${CONTENTS_JSON}")

        if [ "${scale}" == "@1x" ]; then
           scale=""
        fi
        if [ "${idiom}" == "iphone" ]; then
           idiom=""
        fi
        
        if [ "${filename}" == "null" ]; then
            continue
        fi

        SOURCE_ICON_FOLDER="${CONTENTS_JSON//Contents.json/}"
        SOURCE_ICON_PATH="${SOURCE_ICON_FOLDER}/${filename}"
        TARGET_ICON_PATH="${SOURCE_ICON_PATH}"

        if [ ! -e "${SOURCE_ICON_PATH}" ]; then
            echo "Warning: App icon not found: ${SOURCE_ICON_PATH}"
            continue
        fi

        WIDTH=$(identify -format %w "${SOURCE_ICON_PATH}")

        SCRIPT_DIR=$(dirname "${BASH_SOURCE[0]}")
        CACHE_APPICON_PATH="${SCRIPT_DIR}/generate-icons-caches/${WIDTH}"

        if [ ! -e "${CACHE_APPICON_PATH}" ]; then
            mkdir -p "${CACHE_APPICON_PATH}"
        fi

        if [ "${CONFIGURATION}" == "Release" ] || [ "${CONFIGURATION}" == "Release_AppCenter" ]; then
    	    TITLE="Demo"
        elif [ "${CONFIGURATION}" == "Nightly" ] || [ "${CONFIGURATION}" == "Nightly_AppCenter" ]; then
    	    TITLE="Nightly"
        else
            TITLE="Und"
        fi

        SCRIPT_ICON_PATH="${CACHE_APPICON_PATH}/${TITLE}-${filename}"

        if [ "${LAST_RUN}" != "${CURRENT_RUN}" ] || [ ! -e "${SCRIPT_ICON_PATH}" ]; then
            if [ "${idiom}" == "tv" ]; then
              HEIGHT=$(echo "${WIDTH}/16" | bc)  
            else
              HEIGHT=$(echo "${WIDTH}/6" | bc)  
            fi

            if [ "${BUILD_NUMBER}" != "" ]; then
                CAPTION="${TITLE}-${BUILD_NUMBER}"
            else
                CAPTION="${TITLE}"
            fi

            if [ "${DEVELOPMENT_TEAM}" == "VMGRRW6SG7" ]; then
                BACKGROUND="#0001"
                FILL="black"
            else
                BACKGROUND="#000A"
                FILL="white"
            fi

            echo "Making app icon ${CAPTION} | ${filename}"
            convert -background "${BACKGROUND}" -fill "${FILL}" -gravity center -size "${WIDTH}x${HEIGHT}" caption:"${CAPTION}" "${SOURCE_ICON_PATH}" +swap -gravity south -composite "${SCRIPT_ICON_PATH}"
            convert -background "${BACKGROUND}" -fill "${FILL}" -gravity center -size "${WIDTH}x${HEIGHT}" caption:"${VERSION_STRING}" "${SCRIPT_ICON_PATH}" +swap -gravity north -composite "${SCRIPT_ICON_PATH}"

        fi

        SOURCE_ICON_PATH="${SCRIPT_ICON_PATH}"
        cp -f "${SOURCE_ICON_PATH}" "${TARGET_ICON_PATH}"
    done
done

if [ -f "$LAST_RUN_FILE" ]; then
    rm "$LAST_RUN_FILE";
fi

echo "$CURRENT_RUN" > "$LAST_RUN_FILE"

echo "After the compilation execute 'generate-icons-restore.sh' to restore original app icons."
exit 0
