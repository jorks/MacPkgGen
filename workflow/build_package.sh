#!/bin/bash
# set -x
# This is the script that is executed by the workflow to build the package.
# TODO:
# - Export Name and Version to GitHub for use in release


MP_BIN_DIR="/tmp/munki-pkg"
SCRIPT_DIR=$( realpath "${0}" )
BASE_DIR=$( dirname "${SCRIPT_DIR}" )
PROJECT_DIR=$( dirname "${BASE_DIR}" )
UPLOAD_DIR="${PROJECT_DIR}/uploads"

echo "Project directory is: ${PROJECT_DIR}"

# Find the build-info file and set the package directory
BUILD_INFO_FILE="$( find "${PROJECT_DIR}" -name "build-info*" -print )"
if [[ -z "${BUILD_INFO_FILE}" ]]; then
	echo "Error no build-info file found. Exiting." 1>&2
	exit 1
else
	PKG_PATH="$( dirname "${BUILD_INFO_FILE}" )"
	echo "Found package path: ${PKG_PATH}"
fi


# Write out the Package Version and Name
case ${BUILD_INFO_FILE} in
	*.json|*.plist )
		PKG_NAME=$( /usr/bin/plutil -extract name raw -o - - < "${BUILD_INFO_FILE}" | sed 's/-.*//' )
		PKG_VERSION=$( /usr/bin/plutil -extract version raw -o - - < "${BUILD_INFO_FILE}" )

		echo "Found Name: ${PKG_NAME}"
		echo "Found Version: ${PKG_VERSION}"
		;;
	* )
		echo "Error: Unrecognised file format. Exiting." 1>&2
		exit 1
		;;
esac


# Running execution test
echo "Check: can run munki-pkg with python3 from PATH..."

MP_VERSION=$( python3 ${MP_BIN_DIR}/munkipkg --version )
if [[ -z "${MP_VERSION}" ]] ; then
	echo "Error: can not execut munkipkg --version" 1>&2
	if [[ ! -f ${MP_BIN_DIR}/munkipkg ]]; then echo "Error: can not find munki-pkg" 1>&2; fi
	if ! command -v python3 &> /dev/null; then echo "Error: can not find python3"  1>&2; fi
	exit 1
else
	echo "Success: installed munki-pkg version: ${MP_VERSION}"	
fi


# Perfom a BOM file sync if running on github
if [[ -d "/Users/runner" ]]; then
    echo "Status: We are running on a github runner"
    echo "Running a project Sync with the BOM file"
    python3 "${MP_BIN_DIR}/munkipkg" --sync "$PKG_PATH"
fi


# Build the package
echo "Running: Building Package.."
python3 "${MP_BIN_DIR}/munkipkg" "$PKG_PATH"
PKG_RESULT="$?"
if [ "${PKG_RESULT}" != "0" ]; then
	echo "Error: Could not sign package: ${PKG_RESULT}" 1>&2
else
	echo "Success: Package was built ${PKG_RESULT}"
fi



# TODO: Notarize Nudge PKG
# This is how it can be done:

# # Setup notary credentials into the workflow keychain
# xcrun notarytool store-credentials --apple-id "opensource@macadmins.io" --team-id "T4SK8ZXCXG" --password "$2" workflow

# # Notarize nudge package
# xcrun notarytool submit "$NUDGE_PKG_PATH/build/Nudge-$AUTOMATED_NUDGE_BUILD.pkg" --keychain-profile "workflow" --wait
# xcrun stapler staple "$NUDGE_PKG_PATH/build/Nudge-$AUTOMATED_NUDGE_BUILD.pkg"


# TODO: Move the package into a generic output directory
# Move the signed pkg
# Create outputs folder

if [[ ! -d "/Users/runner" ]]; then
	echo "Status: We are running on a github runner"
    if [[ -d "${UPLOAD_DIR}" ]]; then
  		/bin/rm -rf "${UPLOAD_DIR}"
	fi
	echo "Creating an uploads directory and adding files"
	/bin/mkdir -p "${UPLOAD_DIR}"
	/bin/mv "${PKG_PATH}/build/${PKG_NAME}-${PKG_VERSION}.pkg" "${UPLOAD_DIR}"
	echo "Adding build info files"
	echo "${PKG_NAME}" > "${UPLOAD_DIR}/build-name.txt"
	echo "${PKG_VERSION}" > "${UPLOAD_DIR}/build-version.txt"
fi





