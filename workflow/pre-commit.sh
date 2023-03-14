#!/bin/sh

# This script will ensure a BOM file is created or updated at commit
# File is .git/hooks/pre-commit

MP_BIN_DIR="/tmp/munki-pkg"
SCRIPT_DIR=$( realpath "${0}" )
BASE_DIR_1=$( dirname "${SCRIPT_DIR}" )
BASE_DIR_2=$( dirname "${BASE_DIR_1}" )
PROJECT_DIR=$( dirname "${BASE_DIR_2}" )

echo "Project directory is: ${PROJECT_DIR}"

# Find the build-info file and set the package directory
BUILD_INFO_FILE="$( find "${PROJECT_DIR}" -name "build-info*" -print )"
if [ -z "${BUILD_INFO_FILE}" ]; then
	echo "Error no build-info file found. Exiting." 1>&2
	exit 1
else
	PKG_PATH="$( dirname "${BUILD_INFO_FILE}" )"
	echo "Found package path: ${PKG_PATH}"
fi

# Create a BOM File when we do git commits
if [ ! -d "/Users/runner" ]; then
    echo "Status: We are running on a local clone"
    echo "Exporting a BOM info file"
    python3 "${MP_BIN_DIR}/munkipkg" --export-bom-info "$PKG_PATH"
fi

exit 0