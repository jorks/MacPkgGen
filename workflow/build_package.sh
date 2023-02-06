#!/bin/bash
# set -x
# This is the script that is executed by the workflow to build the package.


MP_BINDIR="/tmp/munki-pkg"
SCRIPT_DIR=$( pwd )
BASE_DIR="$( dirname "$SCRIPT_DIR" )"


# Find the build-info file and set the package directory
BUILD_INFO_FILE="$( find "$BASE_DIR" -name "build-info*" -print )"
if [[ -z "$BUILD_INFO_FILE" ]]; then
	echo "Error no build-info file found. Exiting." 1>&2
	exit 1
else
	PKG_PATH="$( dirname "$BUILD_INFO_FILE" )"
	echo "Found package path: $PKG_PATH"
fi


# Running execution test
echo "Check: can run munki-pkg with python3 from PATH..."

MP_VERSION=$( python3 ${MP_BINDIR}/munkipkg --version )
if [[ -z "${MP_VERSION}" ]] ; then
	echo "Error executing munkipkg --version" 1>&2
	if [[ ! -f ${MP_BINDIR}/munkipkg ]]; then echo "Error: can not find munki-pkg" 1>&2; fi
	if ! command -v python3 &> /dev/null; then echo "Error: can not find python3"  1>&2; fi
	exit 1
else
	echo "Success: installed munki-pkg version: ${MP_VERSION}"	
fi


# Build the package
echo "Running: Building Package.."
python3 "${MP_BINDIR}/munkipkg" "$PKG_PATH"
PKG_RESULT="$?"
if [ "${PKG_RESULT}" != "0" ]; then
	echo "Error: Could not sign package: ${PKG_RESULT}" 1>&2
else
	echo "Success: Package was built ${PKG_RESULT}"
fi