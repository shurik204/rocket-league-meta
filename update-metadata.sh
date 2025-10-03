#!/bin/bash
set -e

chmod +x calculate_build_id.py convert_to_json.py

strings /tmp/rocketleague/Binaries/Win64/RocketLeague.exe > rocketleague.txt
strings -e l /tmp/rocketleague/Binaries/Win64/RocketLeague.exe > rocketleague-16.txt

function get_feature_set() {
    local FEATURE_SET=$(cat rocketleague-16.txt | grep -E 'Update[0-9]+' | uniq -d | head -1)
    local UPDATE_NUMBER=$(cat rocketleague-16.txt | grep -E '^Update[0-9]+[a-Z_0-9]*' | head -1)
    if [[ "$FEATURE_SET" == *"$UPDATE_NUMBER"* ]]; then
        echo "$FEATURE_SET";
    else
        echo "[!] Feature set \"$FEATURE_SET\" does not contain expected \"$UPDATE_NUMBER\""
        exit 4
    fi
}

BUILD_DATE=$(cat rocketleague.txt | grep -E '[A-Z][a-z]+ {1,3}[0-9]+ 20[0-9]+ [0-9]+:[0-9]+:[0-9]+' | head -1)
G_PSYONIX_BUILD_ID=$(cat rocketleague-16.txt | grep -E '[0-9]{2,}\.[0-9]{2,}\.[0-9]{2,}' | head -1)
PSY_BUILD_ID=$(./calculate_build_id.py "$G_PSYONIX_BUILD_ID")
FEATURE_SET=$(get_feature_set)

strings rocketleague/Binaries/Win64/EOSSDK-Win64-Shipping.dll > eossdk.txt
strings -e l rocketleague/Binaries/Win64/EOSSDK-Win64-Shipping.dll > eossdk-16.txt

EOSSDK_VERSION=$(cat eossdk-16.txt | grep -E '^([0-9]+\.){2,}[0-9]-[a-Z0-9]+' | head -1)

rm -f rocket_league_info 2> /dev/null

echo "build_date=$BUILD_DATE" >> rocket_league_info
echo "g_psyonix_build_id=$G_PSYONIX_BUILD_ID" >> rocket_league_info
echo "psy_build_id=$PSY_BUILD_ID" >> rocket_league_info
echo "feature_set=$FEATURE_SET" >> rocket_league_info

rm -f eos_sdk_info 2> /dev/null

echo "eos_sdk_version=$EOSSDK_VERSION" >> eos_sdk_info

mkdir -p data

./convert_to_json.py rocket_league_info data/rocket_league.json
./convert_to_json.py eos_sdk_info data/eos_sdk.json

mv "$LEGENDARY_CONFIG_PATH/manifests/"Sugar_Windows_*.manifest data/Sugar.manifest

echo "build_id=$G_PSYONIX_BUILD_ID" >> $GITHUB_OUTPUT