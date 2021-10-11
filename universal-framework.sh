#!/bin/bash

set -e
# Make sure to run this script in Framework folder to work properly.
# Create universal-framework.sh and copy all content to it.
# Provide FRAMEWORK_NAME to start build

# Globals Variables

# Avilable Platforms/Architectures 
# macosx | iphoneos | iphonesimulator | appletvos | appletvsimulator | watchos | watchsimulator
DEVICE_ARCH="iphoneos"
DEVICE_SIM_ARCH="iphonesimulator"

FRAMEWORK_NAME=""
FRAMEWORK_DIR_PATH="$(pwd)"/${FRAMEWORK_NAME}-Universal
BUILD_DIR_PATH=${FRAMEWORK_DIR_PATH}/build
DERIVED_DATA_DIR_PATH=${FRAMEWORK_DIR_PATH}/derived-data
LOG_PATH=${FRAMEWORK_DIR_PATH}/logs
SIMULATOR_DIR_PATH=${BUILD_DIR_PATH}/simulator
DEVICES_DIR_PATH=${BUILD_DIR_PATH}/devices
UNIVERSAL_LIBRARY_DIR_PATH=${BUILD_DIR_PATH}/universal
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

makeDirectories()
{
  mkdir -p "${LOG_PATH}"
  mkdir -p "${SIMULATOR_DIR_PATH}"
  mkdir -p "${DEVICES_DIR_PATH}"
  mkdir -p "${UNIVERSAL_LIBRARY_DIR_PATH}"
}

######################

# Cleaning up old directories if available.

if [ -d "${FRAMEWORK_DIR_PATH}/" ]; then
rm -rf "${FRAMEWORK_DIR_PATH}"
fi

# Make sure we have all directories available to work.

makeDirectories

# Start with logging process

exec > ${LOG_PATH}/${FRAMEWORK_NAME}_archive.log 2>&1
open ${LOG_PATH}/${FRAMEWORK_NAME}_archive.log
printStatement "\n ⏱ Starting the Building Process for Universal Framework... \n\n\n"

# Printing the PATHS

printPaths

######################

printStatement "${ROW_STRING}"
printStatement "\n\n\n 🚀 Step 1-1: Building for ${DEVICE_SIM_ARCH}"
printStatement "${ROW_STRING}"

EXIT_MESSAGE="$(xcodebuild clean build BITCODE_GENERATION_MODE=bitcode OTHER_CFLAGS="-fembed-bitcode" -workspace "${FRAMEWORK_NAME}.xcworkspace" -scheme "${FRAMEWORK_NAME}" -configuration Release -sdk "${DEVICE_SIM_ARCH}" -derivedDataPath "${DERIVED_DATA_DIR_PATH}")"


checkSuccess

######################

printStatement "${ROW_STRING}"
printStatement "\n\n\n 📦 Step 1-2: Copy the framework structure for ${DEVICE_SIM_ARCH}"
printStatement "${ROW_STRING}"

cp -r ${DERIVED_DATA_DIR_PATH}/Build/Products/Release-${DEVICE_SIM_ARCH}/${FRAMEWORK_NAME}.framework ${SIMULATOR_DIR_PATH}

######################

printStatement "${ROW_STRING}"
printStatement "\n\n\n 🚀 Step 2-1: Building for ${DEVICE_ARCH} \n\n\n"

EXIT_MESSAGE="$(xcodebuild clean build BITCODE_GENERATION_MODE=bitcode OTHER_CFLAGS="-fembed-bitcode" -workspace ${FRAMEWORK_NAME}.xcworkspace -scheme ${FRAMEWORK_NAME} -configuration Release -sdk "${DEVICE_ARCH}" -derivedDataPath "${DERIVED_DATA_DIR_PATH}")"


checkSuccess

######################

printStatement "${ROW_STRING}"
printStatement "\n\n\n 📦 Step 2-2: Copy the framework structure for ${DEVICE_ARCH}"
printStatement "${ROW_STRING}"

cp -r ${DERIVED_DATA_DIR_PATH}/Build/Products/Release-${DEVICE_ARCH}/${FRAMEWORK_NAME}.framework ${DEVICES_DIR_PATH}

######################

printStatement "${ROW_STRING}"
printStatement "\n\n\n 🛠 Step 3: Copy device framework into universal folder"
printStatement "${ROW_STRING}"

if [ -d "${DEVICES_DIR_PATH}/${FRAMEWORK_NAME}.framework/" ]; then

cp -r ${DEVICES_DIR_PATH}/${FRAMEWORK_NAME}.framework "${UNIVERSAL_LIBRARY_DIR_PATH}/" | printStatement

else 
    printStatement "ℹ️ Couldn't find any Framework file for DEVICE!"
fi

######################

printStatement "${ROW_STRING}"
printStatement "\n\n\n 🛠 Step 4: The LIPO Step i.e. Creating Universal Framework"
printStatement "${ROW_STRING}"

lipo -create \
  ${SIMULATOR_DIR_PATH}/${FRAMEWORK_NAME}.framework/${FRAMEWORK_NAME} \
  ${DEVICES_DIR_PATH}/${FRAMEWORK_NAME}.framework/${FRAMEWORK_NAME} \
  -output ${UNIVERSAL_LIBRARY_DIR_PATH}/${FRAMEWORK_NAME}.framework/${FRAMEWORK_NAME}

######################

printStatement "${ROW_STRING}"
printStatement "\n\n\n 🛠 Step 5: Copy simulator Swift public interface to universal framework"
printStatement "${ROW_STRING}"

if [ -d "${SIMULATOR_DIR_PATH}/${FRAMEWORK_NAME}.framework/Modules/${FRAMEWORK_NAME}.swiftmodule/" ]; then

cp ${SIMULATOR_DIR_PATH}/${FRAMEWORK_NAME}.framework/Modules/${FRAMEWORK_NAME}.swiftmodule/* ${UNIVERSAL_LIBRARY_DIR_PATH}/${FRAMEWORK_NAME}.framework/Modules/${FRAMEWORK_NAME}.swiftmodule | printStatement

else 
    printStatement "ℹ️ Couldn't find any Swift module file for SIMULATOR!"
fi

######################

# Open the Framework directory

printStatement "${ROW_STRING}"
printStatement "\n\n\n 🛠 Step 6: Zip framework file"
printStatement "${ROW_STRING}"

cd "${UNIVERSAL_LIBRARY_DIR_PATH}"
zip -r9 "${FRAMEWORK_NAME}-$(date +"%Y%m%d%H%M%S")".framework.zip "${FRAMEWORK_NAME}".framework

######################

# Open the Framework directory

printStatement "${ROW_STRING}"
open "${UNIVERSAL_LIBRARY_DIR_PATH}"
printStatement "${ROW_STRING}"

######################

# Open the log file on Console application

exitWithMessage
