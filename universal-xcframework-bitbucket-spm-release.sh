#!/bin/bash

set -e
# Make sure to run this script in Framework folder to work properly.
# Create universal-xcframework.sh and copy all content to it.
# Provide FRAMEWORK_NAME to start build

# Globals Variables

# Avilable Platforms/Architectures
# macosx | iphoneos | iphonesimulator | appletvos | appletvsimulator | watchos | watchsimulator
DEVICE_ARCH="iphoneos"
DEVICE_SIM_ARCH="iphonesimulator"

FRAMEWORK_NAME=""
BITBUCKET_WORKSPACE_NAME=""
BITBUCKET_REPO_NAME=""
BASE_FIRMWARE_PATH="$(pwd)"
FRAMEWORK_DIR_PATH="${BASE_FIRMWARE_PATH}"/${FRAMEWORK_NAME}-Universal
BUILD_DIR_PATH=${FRAMEWORK_DIR_PATH}/build
DERIVED_DATA_DIR_PATH=${FRAMEWORK_DIR_PATH}/derived-data
LOG_PATH=${FRAMEWORK_DIR_PATH}/logs
SIMULATOR_DIR_PATH=${BUILD_DIR_PATH}/simulator
DEVICES_DIR_PATH=${BUILD_DIR_PATH}/devices
UNIVERSAL_LIBRARY_DIR_PATH=${BUILD_DIR_PATH}/universal
DATETIME="$(date +"%Y%m%d%H%M%S")"
FRAMEWORK_NAME_DATETIME="$FRAMEWORK_NAME-$DATETIME"
SERVER_PATH="$BASE_FIRMWARE_PATH/../OLNetworkFiles/files"
NEW_VERSION=$1
SUCCESS=true
EXIT_MESSAGE=$?
ROW_STRING="\n##################################################################\n"

######################

printStatement()
{
    echo -e "$1"
}

printPaths()
{
    printStatement "${ROW_STRING}"
    printStatement "BUILD_DIR: ${BUILD_DIR_PATH}"
    printStatement "DERIVED_DATA_DIR: ${DERIVED_DATA_DIR_PATH}"
    printStatement "LOG_PATH: ${LOG_PATH}"
    printStatement "DEVICE_LIBRARY_PATH: ${DEVICES_DIR_PATH}"
    printStatement "SIMULATOR_LIBRARY_PATH: ${SIMULATOR_DIR_PATH}"
    printStatement "UNIVERSAL_LIBRARY_DIR: ${UNIVERSAL_LIBRARY_DIR_PATH}"
    printStatement "DATETIME: ${DATETIME}"
    printStatement "FRAMEWORK_NAME_DATETIME: ${FRAMEWORK_NAME_DATETIME}"
    printStatement "NEW_VERSION: ${NEW_VERSION}"
    printStatement "${ROW_STRING}"
}

checkSuccess()
{
    if [[ -z $EXIT_MESSAGE ]]; then
        SUCCESS=false
        exitWithMessage
        exit 1
    fi
}

exitWithMessage()
{
    printStatement "${ROW_STRING}"

    if [ "$SUCCESS" = true ] ; then
        printStatement "\n\n\n 🏁 Completed with Success! 🙂"
    else
        printStatement "\n\n\n 😱 Completed with Errors! Please check line above for details:"
        printStatement "${EXIT_MESSAGE}"
    fi

    printStatement "\n 🔍 For more details you can always check the ${LOG_PATH}/${FRAMEWORK_NAME}_archive.log file. 📝 \n\n\n"
    printStatement "${ROW_STRING}"
}

handle_error()
{
    printStatement "\n\n\n 😱 Completed with Errors!"
    printStatement "\n\n\n 🚨 Error : $?\n\n\n"
    printStatement "${ROW_STRING}"
    printStatement "Cleaning up the directories..."
    cd "${BASE_FIRMWARE_PATH}"/../"${FRAMEWORK_NAME}"
    rm -f *.zip
    exit 1
}

makeDirectories()
{
  mkdir -p "${LOG_PATH}"
  mkdir -p "${SIMULATOR_DIR_PATH}"
  mkdir -p "${DEVICES_DIR_PATH}"
  mkdir -p "${UNIVERSAL_LIBRARY_DIR_PATH}"
  mkdir -p "${SERVER_PATH}"
}

is_semver() {
  [[ "$1" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
}

######################

# Check for arguments
if [ $# -eq 0 ]; then
    printStatement "\nNo arguments provided. First argument has to be version, e.g. '1.8.1'\n"
    exit 1
fi

if is_semver "$NEW_VERSION"; then
  printStatement "\n✅ '$NEW_VERSION' is a valid semantic version\n"
else
  printStatement "\n❌ '$NEW_VERSION' is NOT a valid semantic version\n"
  exit 1
fi

REQUIRED_VARS=("FRAMEWORK_NAME" "BITBUCKET_WORKSPACE_NAME" "BITBUCKET_REPO_NAME")

for var in "${REQUIRED_VARS[@]}"; do
  if [[ -z "${!var}" ]]; then
    printStatement "\n❌ '$var' is not set or empty.\n"
    exit 1
  fi
done

printStatement "✅ All variables are set. Proceeding..."

######################

# Cleaning up old directories if available.

if [ -d "${FRAMEWORK_DIR_PATH}/" ]; then
rm -rf "${FRAMEWORK_DIR_PATH}"
fi

# Make sure we have all directories available to work.

makeDirectories

# Start with logging process

exec > >(tee "${LOG_PATH}/${FRAMEWORK_NAME}_archive.log") 2>&1
printStatement "\n ⏱ Starting the Building Process for Universal Framework... \n\n\n"

trap handle_error ERR

# Printing the PATHS

printPaths

######################

printStatement "${ROW_STRING}"
printStatement "\n\n\n 🚀 Step 1: Archiving for ${DEVICE_SIM_ARCH}"
printStatement "${ROW_STRING}"


EXIT_MESSAGE="$(xcodebuild archive -scheme "${FRAMEWORK_NAME}" -destination="generic/platform=iOS Simulator" -archivePath "${SIMULATOR_DIR_PATH}"/"${DEVICE_SIM_ARCH}".xcarchive -derivedDataPath "${DERIVED_DATA_DIR_PATH}" -sdk "${DEVICE_SIM_ARCH}" SKIP_INSTALL=NO BUILD_LIBRARY_FOR_DISTRIBUTION=YES)"


checkSuccess

######################

printStatement "${ROW_STRING}"
printStatement "\n\n\n 🚀 Step 2: Archiving for ${DEVICE_ARCH} \n\n\n"


EXIT_MESSAGE="$(xcodebuild archive -scheme "${FRAMEWORK_NAME}" -destination="generic/platform=iOS" -archivePath "${DEVICES_DIR_PATH}"/"${DEVICE_ARCH}".xcarchive -derivedDataPath "${DERIVED_DATA_DIR_PATH}" -sdk "${DEVICE_ARCH}" SKIP_INSTALL=NO BUILD_LIBRARY_FOR_DISTRIBUTION=YES)"


checkSuccess

######################

printStatement "${ROW_STRING}"
printStatement "\n\n\n 🛠 Step 3: XCFramework: Generating IPHONE BCSymbolMap paths..."
printStatement "${ROW_STRING}"

IPHONE_BCSYMBOLMAP_COMMANDS="$(find ${DEVICES_DIR_PATH}/${DEVICE_ARCH}.xcarchive/BCSymbolMaps -type f -print0 | xargs -0 -I {} echo "-debug-symbols {}" | tr "\n" " ")"

######################

printStatement "${ROW_STRING}"
printStatement "\n\n\n 🛠 Step 4: Creating XC Framework into universal folder"
printStatement "${ROW_STRING}"

xcodebuild -create-xcframework \
 -framework "${DEVICES_DIR_PATH}"/"${DEVICE_ARCH}".xcarchive/Products/Library/Frameworks/"${FRAMEWORK_NAME}".framework \
 -debug-symbols "${DEVICES_DIR_PATH}"/"${DEVICE_ARCH}".xcarchive/dSYMs/"${FRAMEWORK_NAME}".framework.dSYM $IPHONE_BCSYMBOLMAP_COMMANDS \
 -framework "${SIMULATOR_DIR_PATH}"/"${DEVICE_SIM_ARCH}".xcarchive/Products/Library/Frameworks/"${FRAMEWORK_NAME}".framework \
 -debug-symbols "${SIMULATOR_DIR_PATH}"/"${DEVICE_SIM_ARCH}".xcarchive/dSYMs/"${FRAMEWORK_NAME}".framework.dSYM \
 -output "${UNIVERSAL_LIBRARY_DIR_PATH}"/"${FRAMEWORK_NAME}".xcframework

######################

printStatement "${ROW_STRING}"
printStatement "\n\n\n 🛠 Step 5: Zip XC Framework into universal folder"
printStatement "${ROW_STRING}"

cd "${UNIVERSAL_LIBRARY_DIR_PATH}"
zip -r9 "$FRAMEWORK_NAME_DATETIME-$NEW_VERSION.xcframework.zip" "${FRAMEWORK_NAME}".xcframework

######################

# Open the Framework directory

# printStatement "${ROW_STRING}"
# open "${UNIVERSAL_LIBRARY_DIR_PATH}"
# printStatement "${ROW_STRING}"

##############################

printStatement "${ROW_STRING}"
printStatement "\n\n\n 🛠 Step 6: Copy framework to Package directory, extract and them remove"
printStatement "${ROW_STRING}"

cd "${BASE_FIRMWARE_PATH}"/../"${FRAMEWORK_NAME}"
cp -f "${UNIVERSAL_LIBRARY_DIR_PATH}"/$FRAMEWORK_NAME_DATETIME-$NEW_VERSION.xcframework.zip .

##############################

printStatement "\n\n\n 🛠 Step 7: Calculate checksum and store it"
NEW_CHECKSUM=$(swift package compute-checksum $FRAMEWORK_NAME_DATETIME-$NEW_VERSION.xcframework.zip)
printStatement "\n\nprint out new shasum for convenience reasons"
printStatement "\n\nNew checksum is $NEW_CHECKSUM"

##############################

printStatement "\n\n\n 🛠 Step 8: Replace all data from Package.swift manifest"
printStatement "\n\nreplace name module information in package manifest"
sed -E -i '' 's/let moduleName = ".+"/let moduleName = "'$FRAMEWORK_NAME\"/ Package.swift
printStatement "\n\nreplace version information in package manifest"
sed -E -i '' 's/let version = ".+"/let version = "'$NEW_VERSION\"/ Package.swift
printStatement "\n\nreplace checksum information in package manifest"
sed -E -i '' 's/let checksum = ".+"/let checksum = "'$NEW_CHECKSUM\"/ Package.swift
printStatement "\n\nreplace Filename information in package manifest"
sed -E -i '' 's/let filename = ".+"/let filename = "'$FRAMEWORK_NAME_DATETIME\"/ Package.swift

##############################

printStatement "\n\n\n 🛠 Step 9: print out package manifest for convenience reasons"
cat Package.swift

##############################

printStatement "\n\n\n 🛠 Step 10: Releasing the new version"

curl -n -X POST "https://api.bitbucket.org/2.0/repositories/$BITBUCKET_WORKSPACE_NAME/$BITBUCKET_REPO_NAME/downloads" --form files=@"$FRAMEWORK_NAME_DATETIME-$NEW_VERSION.xcframework.zip"

##############################

printStatement "\n\n\n 🛠 Step 11: Delete the framework file"
rm -f $FRAMEWORK_NAME_DATETIME-$NEW_VERSION.xcframework.zip

##############################

printStatement "\n\n\n 🛠 Step 12: Commit all data without the XCfrmework and push"
echo "git commit all without framework and push"
git add --all
git commit -m "New $FRAMEWORK_NAME version $NEW_VERSION"
git tag -a $NEW_VERSION -m "New $FRAMEWORK_NAME version $NEW_VERSION"
git push --follow-tags

######################

exitWithMessage
