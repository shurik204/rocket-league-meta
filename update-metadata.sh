#!/bin/bash
set -Eeuo pipefail
set -x

grep --version | head -1
if [ -z "$GAME_INSTALL_DIR" ]; then
    GAME_INSTALL_DIR='/tmp/rocketleague'
fi
echo "Game install directory: '$GAME_INSTALL_DIR'"

# Install scripts requirements
pip install -r requirements.txt
chmod +x calculate_build_id.py convert_to_json.py

# Rocket League data
echo "Extracting Rocket League data"

strings "$GAME_INSTALL_DIR/Binaries/Win64/RocketLeague.exe" > rocketleague.txt
strings -e l "$GAME_INSTALL_DIR/Binaries/Win64/RocketLeague.exe" > rocketleague-16.txt

function get_feature_set() {
    local FEATURE_SET=$(cat rocketleague-16.txt | grep -E 'Update[0-9]+' | uniq -d | head -1)
    local UPDATE_NUMBER=$(cat rocketleague-16.txt | grep -E '^Update[0-9]+[A-z_0-9]*' | head -1)
    if [ -z "$UPDATE_NUMBER" ]; then
        echo "[!] Failed to get update number!"
        exit 6
    fi
    if [[ "$FEATURE_SET" == *"$UPDATE_NUMBER"* ]]; then
        echo "$FEATURE_SET";
    else
        echo "[!] Feature set \"$FEATURE_SET\" does not contain expected \"$UPDATE_NUMBER\""
        exit 4
    fi
}

rm -f rocket_league_info 2> /dev/null

G_PSYONIX_BUILD_ID=$(cat rocketleague-16.txt | grep -E '[0-9]{2,}\.[0-9]{2,}\.[0-9]{2,}' | head -1)
if [ -z "$G_PSYONIX_BUILD_ID" ]; then
    echo "Failed to extract GPsyonixBuildID"
    exit 8
fi
PSY_BUILD_ID=$(./calculate_build_id.py "$G_PSYONIX_BUILD_ID")
FEATURE_SET=$(get_feature_set)
BUILD_DATE=$(cat rocketleague.txt | grep -E '[A-Z][a-z]{2,8} {1,3}[0-9]+ 20[0-9]+ [0-9]+:[0-9]+:[0-9]+' | head -1)
CURL_VERSION=$(cat rocketleague.txt | grep -E '^libcurl/([0-9]+\.){1,3}[0-9]+' | head -1 | cut -b 9-)

echo "build_date=$BUILD_DATE" >> rocket_league_info
echo "g_psyonix_build_id=$G_PSYONIX_BUILD_ID" >> rocket_league_info
echo "build_id=$PSY_BUILD_ID" >> rocket_league_info
echo "feature_set=$FEATURE_SET" >> rocket_league_info
echo "curl_version=$CURL_VERSION" >> rocket_league_info
# EOS SDK data
echo "Extracting EOS SDK data"

strings "$GAME_INSTALL_DIR/Binaries/Win64/EOSSDK-Win64-Shipping.dll" > eossdk.txt
strings -e l "$GAME_INSTALL_DIR/Binaries/Win64/EOSSDK-Win64-Shipping.dll" > eossdk-16.txt

EOSSDK_VERSION=$(cat eossdk-16.txt | grep -E '^([0-9]+\.){2,}[0-9]-[A-z0-9]+' | head -1)

echo "eos_sdk_version=$EOSSDK_VERSION" >> rocket_league_info

# Collect results
echo "Collecting results"
mkdir -p data

./convert_to_json.py rocket_league_info data/Sugar.json

echo "Writing list of game files"
legendary list-files Sugar > data/files.txt 2> /dev/null

echo "Storing legal texts"
mkdir -p data/Legal
mv "$GAME_INSTALL_DIR/TAGame/Legal/PC/"* data/Legal/
echo "Storing game manifest"
mv "$LEGENDARY_CONFIG_PATH/manifests/"Sugar_Windows_*.manifest data/Sugar.manifest

echo "build_id=$G_PSYONIX_BUILD_ID" >> $GITHUB_OUTPUT