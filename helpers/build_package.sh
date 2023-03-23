#!/bin/bash
# set -x
# This is the script that is executed by the workflow to build the package. 


# Assign Script Input for Notarization Secrets
# Do not hard code these values - use GitHub Secrets!
# Running this script locally will NOT Notarize the package
NOTARIZE_PASSWORD="${1}"
NOTARIZE_APPLE_ID="${2}"
NOTARIZE_TEAM_ID="${3}"


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
		echo "Error: Unrecognised file format. This does not support yaml. Exiting." 1>&2
		exit 1
		;;
esac


# Running execution test
echo "Check: can run munki-pkg with python3 from PATH..."

MP_VERSION=$( python3 ${MP_BIN_DIR}/munkipkg --version )
if [[ -z "${MP_VERSION}" ]] ; then
	echo "Error: can not execute munkipkg --version" 1>&2
	if [[ ! -f ${MP_BIN_DIR}/munkipkg ]]; then echo "Error: can not find munki-pkg" 1>&2; fi
	if ! command -v python3 &> /dev/null; then echo "Error: can not find python3"  1>&2; fi
	exit 1
else
	echo "Success: installed munki-pkg version: ${MP_VERSION}"	
fi


# Perform a BOM file sync if running on GitHub
if [[ -d "/Users/runner" ]]; then
    echo "Status: We are running on a GitHub runner"
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

# Notarize the Package for Gatekeeper
if [[ -n "${NOTARIZE_PASSWORD}" ]] && [[ -n "${NOTARIZE_APPLE_ID}" ]] && [[ -n "${NOTARIZE_TEAM_ID}" ]]; then
	echo "Received valid Notarization details. Will submit the package for Notarization"
	# Setup notary credentials into the GithubWorkflow keychain
	xcrun notarytool store-credentials --apple-id "${NOTARIZE_APPLE_ID}" --team-id "${NOTARIZE_TEAM_ID}" --password "${NOTARIZE_PASSWORD}" GithubWorkflow

	# Notarize and Staple Package
	xcrun notarytool submit "${PKG_PATH}/build/${PKG_NAME}-${PKG_VERSION}.pkg" --keychain-profile "GithubWorkflow" --wait
	xcrun stapler staple "${PKG_PATH}/build/${PKG_NAME}-${PKG_VERSION}.pkg"
	NOTARIZE_STATUS=$?
	if [[ "${NOTARIZE_STATUS}" -ne 0 ]]; then
		echo "Error: Notarization failed"
	fi
else
	echo "Did not receive valid Notarization details. Skipping Notarization"
fi


# Move the Package output into an uploads folder for other workflow steps

if [[ -d "/Users/runner" ]]; then
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

echo "Success: Package was built successfully."
exit 0



